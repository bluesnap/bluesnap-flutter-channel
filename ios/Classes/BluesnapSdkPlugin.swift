import Flutter
import BluesnapSDK
import UIKit

class BluesnapNavigationDelegate: NSObject, UINavigationControllerDelegate {
    var bsPlugin:BluesnapSdkPlugin?

    init(plugin: BluesnapSdkPlugin) {
        self.bsPlugin = plugin
    }
    public func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {

        if (viewController is FlutterViewController) {
            NSLog("Will show Flutter view controller")
            self.bsPlugin?.returningToFlutter()
        }
    }
}

@available(iOS 13.0, *)
public class BluesnapSdkPlugin: NSObject, FlutterPlugin {
   fileprivate var thisbsToken: BSToken?
   fileprivate var shouldInitKount = true
   final fileprivate var shopperId : Int? = nil
   final fileprivate var vaultedShopperId : String? = nil
   final fileprivate var threeDSResult : String? = nil
   var sdkre: BSSdkRequest?
   var navptr: UINavigationController?
   private var purchaseLock: AwaitLock
   private var tokenGenerationLock: AwaitLock
   var methodChannel: FlutterMethodChannel
    
    var oldDelegate:UINavigationControllerDelegate?
    
    var pluginRegistrar : FlutterPluginRegistrar
    
    var viewController:UIViewController?
    
    var navigationControllerDelegate: BluesnapNavigationDelegate?
    
    var waitingForPurchaseComplete: Bool?

     init(methodChannel: FlutterMethodChannel, pluginRegistrar: FlutterPluginRegistrar) {
        self.sdkre = nil
        self.pluginRegistrar = pluginRegistrar
        self.purchaseLock = AwaitLock()
        self.tokenGenerationLock = AwaitLock()
        self.methodChannel = methodChannel
        super.init()
           
        self.navigationControllerDelegate = BluesnapNavigationDelegate(plugin: self)

    }
    
      public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "bluesnap_sdk", binaryMessenger: registrar.messenger())
          

          
        let instance = BluesnapSdkPlugin(methodChannel: channel, pluginRegistrar: registrar)
         registrar.addMethodCallDelegate(instance, channel: channel)
      }

    public func returningToFlutter() {
          let navigationController = self.viewController as? UINavigationController
          if (!(self.oldDelegate is BluesnapNavigationDelegate)) {
              navigationController?.delegate = self.oldDelegate
          }

          navigationController?.setNavigationBarHidden(true, animated: false)

          self.oldDelegate = nil

            
          if (self.waitingForPurchaseComplete ?? false) {
              self.waitingForPurchaseComplete = false
              self.purchaseLock.stopLock(withResult: "userCanceled")
          }
      }
    
  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "initBluesnap":
        self.viewController =  UIApplication.shared.keyWindow?.rootViewController as!  UIViewController

        if let arguments =  call.arguments as? [String: Any]{
            
            let bsToken = arguments["bsToken"] as? String
            let initKount = arguments["initKount"] as? Bool
            let fraudSessionId = arguments["fraudSessionId"] as? String
            let applePayMerchantIdentifier = arguments["applePayMerchantIdentifier"] as? String
            let merchantStoreCurrency = arguments["merchantStoreCurrency"] as? String
            initBluesnap(
                  bsToken, initKount: initKount ?? false,
                  fraudSessionId: fraudSessionId,
                  applePayMerchantIdentifier: applePayMerchantIdentifier,
                  merchantStoreCurrency: merchantStoreCurrency,
                  result: result
            )
        }
        else{
            result(FlutterError(code: "error_code", message: "Invalid parameter", details: nil))
        }
    case "finalizeToken":
        if let token =  call.arguments as? String {
            finalizeToken(token)
            result(nil)
        }
        else{
            result(FlutterError(code: "error_code", message: "Invalid parameter", details: nil))
        }
    case "setSDKRequest":
        if let arguments =  call.arguments as? [String: Any] ,
           let amount = arguments["amount"] as? Double,
           let taxAmount = arguments["taxAmount"] as? Double,
           let currency = arguments["currency"] as? String,
           let withEmail = arguments["withEmail"] as? Bool,
           let withShipping = arguments["withShipping"] as? Bool,
           let fullBilling = arguments["fullBilling"] as? Bool,
           let activate3DS = arguments["activate3DS"] as? Bool
        {

            setSDKRequest(withEmail, withShipping: withShipping, fullBilling: fullBilling,
                          amount: amount, taxAmount: taxAmount, currency: currency,
                          activate3DS: activate3DS)
            result(nil)
        }
        else{
            result(FlutterError(code: "error_code", message: "Invalid parameter", details: nil))
        }
    case "showCheckout":
        showCheckout(result)
    case "checkoutCard":
        if let props =  call.arguments as? [String: Any] {
            checkoutCard(props as NSDictionary, result: result)
        }  else{
            result(FlutterError(code: "error_code", message: "Invalid parameter", details: nil))
        }
       
    default:
      result(FlutterMethodNotImplemented)
    }
  }
    
    /**
        Called by the BlueSnapSDK when token expired error is recognized.
        Here we ask React Native to generate a new token, so that when the action re-tries, it will succeed.
        */
       func generateAndSetBsToken(completion: @escaping (_ token: BSToken?, _ error: BSErrors?) -> Void) {
           NSLog("generateAndSetBSToken, Got BS token expiration notification!")
           
           // Send an event to React Native, asking it to generate a token.
//           sendEvent(withName: "generateToken", body: ["shopperID": shopperId])
           methodChannel.invokeMethod("generateToken", arguments:["shopperID": shopperId])
           Task {
               // Wait for the React Native token generator to call `finalizeToken`.
               await self.tokenGenerationLock.startLock(timeoutSeconds: 3000)
           }
           
           Task {
               // This will run after `finalizeToken` was called.
               if let result = await self.tokenGenerationLock.awaitLock() as? BSToken {
                   completion(result, nil)
               } else {
                   completion(nil, .unknown)
               }
           }
       }
    
    // This function shall only be called from React Native when the token generator finishes generating a token.
      @objc
      func finalizeToken(_ token: String?) -> Void {
          if let token = token, let bsToken = try? BSToken(tokenStr: token) {
              self.tokenGenerationLock.stopLock(withResult: bsToken)
          } else {
              self.tokenGenerationLock.stopLock(withResult: token as NSString?)
          }
      }
    
    private func completePurchase(purchaseDetails: BSBaseSdkResult?) {
        NSLog("ChosenPaymentMethodType: \(String(describing: purchaseDetails?.getCurrency()))")
        self.waitingForPurchaseComplete = false
        self.purchaseLock.stopLock(withResult: purchaseDetails)
    }
    
    func updateTax(_ shippingCountry: String,
                   _ shippingState: String?,
                   _ priceDetails: BSPriceDetails) -> Void {}
    
    @objc
     func setSDKRequest(_ withEmail: Bool,
                        withShipping: Bool,
                        fullBilling: Bool,
                        amount: Double,
                        taxAmount: Double,
                        currency: String,
                        activate3DS: Bool
     ) -> Void {
         self.sdkre = BSSdkRequest(withEmail: withEmail, withShipping: withShipping, fullBilling: fullBilling, priceDetails: BSPriceDetails(amount: amount, taxAmount: taxAmount, currency: currency), billingDetails: nil, shippingDetails: nil, purchaseFunc: completePurchase, updateTaxFunc: updateTax)
         
         self.sdkre?.activate3DS = activate3DS
     }
     
    
    @objc
    func initBluesnap(_ bsToken: String!,
                      initKount: Bool,
                      fraudSessionId: String?,
                      applePayMerchantIdentifier: String?,
                      merchantStoreCurrency: String?,
                      result: @escaping FlutterResult) -> Void {
        // Your implementation here
        print("initBluesnap")
        
        NSLog("initBluesnap, start")
        let semaphore = DispatchSemaphore(value: 0)

        do {
            generateAndSetBsToken { resultToken, errors in
                self.thisbsToken = resultToken
                NSLog("initBluesnap, generateAndSetBsToken")
                do {
                    try BlueSnapSDK.initBluesnap(
                        bsToken: self.thisbsToken,
                        generateTokenFunc: self.generateAndSetBsToken,
                        initKount: self.shouldInitKount,
                        fraudSessionId: nil,
                        applePayMerchantIdentifier: applePayMerchantIdentifier,
                        merchantStoreCurrency: merchantStoreCurrency,
                        completion: { error in
                            if let error = error {
                                NSLog("initBluesnap, error: \(error.description())")
                               
                                result(FlutterError(code: "error_code", message: "Error description", details: nil))
                                
                            } else {
                                NSLog("initBluesnap, Done")
                                
                                result("Success")
                            }
                        })
                    NSLog("initBluesnap, BlueSnapSDK initted blueSnap")
                } catch {
                    var errorText : String = "initBluesnap, Unexpected error: \(error)."
                    NSLog(errorText)
                    result(FlutterError(code: "error_code", message: "Error description",details: errorText))
                }
            }
        }

    }
    
    @objc
      func showCheckout(_ result: @escaping FlutterResult) -> Void {
          NSLog("Show Checkout Screen")
          Task { await self.purchaseLock.startLock(timeoutSeconds: 3000) }
          DispatchQueue.main.async {
              do {
                  NSLog("Show Checkout Screen1\(self.sdkre)")
                 let navigationController1 = self.viewController?.navigationController
                  let navigationController = self.viewController as? UINavigationController
                  self.oldDelegate = navigationController?.delegate
                  navigationController?.delegate = self.navigationControllerDelegate
                  
            
                  do {
                       try BlueSnapSDK.showCheckoutScreen(
                                         inNavigationController: navigationController,
                                         animated: true,
                                         sdkRequest: self.sdkre)
                      self.waitingForPurchaseComplete = true
                  } catch {
                      self.purchaseLock.stopLock(withResult: "Checkout failed: \(error)")
                  }

              } catch {
                  NSLog("Unexpected error: \(error).")
                  self.purchaseLock.stopLock(withResult: error)
              }
          }
          Task {
              let data = await self.purchaseLock.awaitLock()
              if data is BSBaseSdkResult {
                  
                  if let sdkResult = data as? BSBaseSdkResult
                  {
                      let dictionary = DataConverter.convertBSBaseSdkResultToNSDictionary(obj: sdkResult)
                      result(dictionary)
                  }
               
              } else if data is Error {
                  
                  if let error = data as? Error
                  {
                      result(
                        FlutterError(code: "error_code", message: "Error description",details: error.localizedDescription)
                      )
                  }
                  else {
                     result(FlutterError(code: "error_code", message: "Error description",details: nil))
                  }
                  
                  
              }   else if let userCanceled  = data as? String {
                  var dict: [String: Any] =  [:]
                  
                  dict["error"] = "userCanceled"
                  result(dict)
                  
              }
                else {
                  result(FlutterError(code: "error_code", message: "Error description",details: nil))
              }
 
              await (self.viewController as? UINavigationController)?.setNavigationBarHidden(true, animated: true)
          }
      }

      func getCurrentYear() -> Int! {
          let date = Date()
          let calendar = Calendar(identifier: .gregorian)
          let year = calendar.component(.year, from: date)
          return year
      }
      
      public func getExpDateAsMMYYYY(value: String) -> String! {
          let newValue = value
          if let p = newValue.firstIndex(of: "/") {
              let mm = newValue[..<p]
              let yy = BSStringUtils.removeNoneDigits(String(newValue[p..<newValue.endIndex]))
              let currentYearStr = String(getCurrentYear())
              let p1 = currentYearStr.index(currentYearStr.startIndex, offsetBy: 2)
              let first2Digits = currentYearStr[..<p1]
              return "\(mm)/\(first2Digits)\(yy)"
          }
          return ""
      }
    
    
    /**
       *
       */
       public func submitPaymentFields(
           ccn: String,
           cvv: String,
           exp: String,
           purchaseDetails: BSCcSdkResult?,
           result: @escaping FlutterResult
       ) {
           BlueSnapSDK.sdkRequestBase = sdkre
           
           let formattedEXP = getExpDateAsMMYYYY(value: exp)
           
           BSApiManager.submitPurchaseDetails(
               ccNumber: ccn,
               expDate: formattedEXP,
               cvv: cvv,
               last4Digits: nil,
               cardType: nil,
               billingDetails: purchaseDetails?.billingDetails,
               shippingDetails: purchaseDetails?.shippingDetails,
               storeCard: purchaseDetails?.storeCard,
               fraudSessionId: BlueSnapSDK.fraudSessionId,
               completion: { creditCard, error in

                   //exp = getExpDateAsMMYYYY(value: exp)
                   if let error = error {
                       if (error == .invalidCcNumber) {
                           result(FlutterError(code: "error_code", message:  BSValidator.ccnInvalidMessage,details: nil))
                         
                       } else if (error == .invalidExpDate) {
                       
                           result(FlutterError(code: "error_code", message:  BSValidator.expInvalidMessage,details: nil))
                       } else if (error == .invalidCvv) {
                        
                           
                           result(FlutterError(code: "error_code", message:  BSValidator.cvvInvalidMessage,details: nil))
                       } else if (error == .expiredToken) {
                           let message = "An error occurred. Please try again."
                 
                           result(FlutterError(code: "error_code", message:  message,details: nil))
                       } else if (error == .tokenNotFound) {
                           let message = "An error occurred. Please try again."
                       
                           result(FlutterError(code: "error_code", message:  message,details: nil))
                       } else {
                           NSLog("Unexpected error submitting Payment Fields to BS")
                           let message = "An error occurred. Please try again."
                     
                           
                           result(FlutterError(code: "error_code", message:  message,details: nil))
                       }
                   }

                   defer {
                       if let purchaseDetailsR = purchaseDetails {
                           if (BlueSnapSDK.sdkRequestBase?.activate3DS ?? false) {
                               // cardinalCompletion(ccn, creditCard, error)
                               BSCardinalManager.instance.authWith3DS(
                                   currency: purchaseDetailsR.getCurrency(),
                                   amount: String(purchaseDetailsR.getAmount()),
                                   creditCardNumber: ccn,
                                       { cardinalResult, error2 in
                                                                           
                                           if (cardinalResult == ThreeDSManagerResponse.AUTHENTICATION_CANCELED.rawValue) { // cardinal challenge canceled
                                               NSLog(BSLocalizedStrings.getString(BSLocalizedString.Three_DS_Authentication_Required_Error))
                                               let message = BSLocalizedStrings.getString(BSLocalizedString.Three_DS_Authentication_Required_Error)
                                          
                                               
                                               result(FlutterError(code: "error_code", message:  message,details: nil))

                                               
                                           } else if (cardinalResult == ThreeDSManagerResponse.THREE_DS_ERROR.rawValue) { // server or cardinal internal error
                                               NSLog("Unexpected BS server error in 3DS authentication error: \(error2)")
                                               let message = BSLocalizedStrings.getString(BSLocalizedString.Error_Three_DS_Authentication_Error) + "\n" + (error2?.description() ?? "")
                                           
                                               result(FlutterError(code: "error_code", message:  message,details: nil))

                                           } else if (cardinalResult == ThreeDSManagerResponse.AUTHENTICATION_FAILED.rawValue) { // authentication failure
                                               DispatchQueue.main.async {
                                                   self.didSubmitCreditCard(purchaseDetails: purchaseDetails,creditCard: creditCard, error: error,   result: result)
                                               }
                                               
                                           } else { // cardinal success (success/bypass/unavailable/unsupported)
                                               DispatchQueue.main.async {
                                                   self.didSubmitCreditCard(
                                                       purchaseDetails: purchaseDetailsR,
                                                       creditCard: creditCard,
                                                       error: error,
                                                       result: result
                                                      
                                                   )
                                               }
                                           }
                                           
                                       }
                               )
                               
                           } else {
                               DispatchQueue.main.async {
                                   self.didSubmitCreditCard(
                                       purchaseDetails: purchaseDetailsR,
                                       creditCard: creditCard,
                                       error: error,
                                       result: result
                                   )
                               }
                           }
                       }
                   }
               }
           )
       }

       func didSubmitCreditCard(
           purchaseDetails: BSCcSdkResult?,
           creditCard: BSCreditCard,
           error: BSErrors?,
           result: @escaping FlutterResult
       ) {
           if let purchaseResult = purchaseDetails {
               if let errorR = error {
                
                   
                   result(FlutterError(code: "error_code", message:   errorR.description(),details: nil))

               } else {
                   purchaseResult.creditCard = creditCard
                   purchaseResult.threeDSAuthenticationResult = BSCardinalManager.instance.getThreeDSAuthResult()
                   // execute callback
                   BlueSnapSDK.sdkRequestBase?.purchaseFunc(purchaseResult)
                   
                   let dictionary = DataConverter.convertBSBaseSdkResultToNSDictionary(obj: purchaseResult)
                   result(dictionary)
//                   result(FlutterError(code: "error_code", message:      "Payment result empty",details: nil))
               }
               
           } else {
              
               
               result(FlutterError(code: "error_code", message: "Payment result empty",details: nil))

           }
       }
       
       @objc
       func checkoutCard(_ props: NSDictionary,
                         result: @escaping FlutterResult
       ) -> Void {
           var checkoutProps = DataConverter.toCheckoutCardProps(dict: props)
           NSLog("checkoutCard start for card \(checkoutProps.cardNumber)")
          if let request = self.sdkre {
               request.shopperConfiguration.billingDetails?.name = checkoutProps.name
               request.shopperConfiguration.billingDetails?.zip = checkoutProps.billingZip
               request.shopperConfiguration.billingDetails?.email = checkoutProps.email
              
              let purchaseDetails = BSCcSdkResult(sdkRequestBase: request)
              submitPaymentFields(
                  ccn: checkoutProps.cardNumber,
                  cvv: checkoutProps.cvv,
                  exp: checkoutProps.expirationDate,
                  purchaseDetails: purchaseDetails,
                  result: result
              )
          } else {
              result(FlutterError(code: "error_code", message:      "Invalid request",details: nil))
          }
       }

}




