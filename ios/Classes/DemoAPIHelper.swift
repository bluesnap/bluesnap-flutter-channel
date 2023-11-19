//
//  DemoAPIHelper.swift
//  bluesnap-sdk-react-native
//
//  Created by oz on 10/07/2023.
//
import Foundation
import PassKit
import BluesnapSDK

class DemoAPIHelper {
    //temporary
    /* **EXPLANATION**
     
     With the move to SPM, the way resources are bundled with the product changes radically.
     Resources are now hosted in their own separate bundle package with its own identifier.
     
     Xcode has a peculiar quirk where if you have a UI test runner and your test calls functions
     from the application itself directly without triggering any UI actions - the call to Bundle
     will change to favor the test runner's bundle and not the app's bundle, losing access to the resource bundle entirely.
     
     These multiple way to access the bundle take care of that.
     The biggest downside of this solution is that it's extremely fragile - don't change the library's
     target name from "BluesnapSDK" to something else or else this code will fail almost 100% of the time.
     */
    static var bsAPIUser: String {
        guard Bundle(identifier: "BluesnapSDK-BluesnapSDK-resources")?.url(forResource: "credentials", withExtension: "plist") == nil else {
            let credentialsURL = Bundle(identifier: "BluesnapSDK-BluesnapSDK-resources")!.url(forResource: "credentials", withExtension: "plist")!
            
            let dict = NSDictionary(contentsOfFile: credentialsURL.relativePath) as! Dictionary<String, String>
            
            return dict["BsAPIUser"]!
        }
        
        guard Bundle(url: Bundle(for: self).bundleURL.appendingPathComponent("BluesnapSDK_BluesnapSDK.bundle"))?.url(forResource: "credentials", withExtension: "plist") == nil else {
            let credentialsURL = Bundle(url: Bundle(for: self).bundleURL.appendingPathComponent("BluesnapSDK_BluesnapSDK.bundle"))!.url(forResource: "credentials", withExtension: "plist")!
            let dict = NSDictionary(contentsOfFile: credentialsURL.relativePath) as! Dictionary<String, String>
            
            return dict["BsAPIUser"]!
        }
        
        guard let credentialsURL = Bundle(for: self).url(forResource: "credentials", withExtension: "plist"),
              let dict = NSDictionary(contentsOfFile: credentialsURL.relativePath) as? Dictionary<String, String>
        else {
            return "USER_UNDEFINED"
        }
        
        return dict["BsAPIUser"]!
    }
    
    static var bsAPIPassword: String {
        guard Bundle(identifier: "BluesnapSDK-BluesnapSDK-resources")?.url(forResource: "credentials", withExtension: "plist") == nil else {
            let credentialsURL = Bundle(identifier: "BluesnapSDK-BluesnapSDK-resources")!.url(forResource: "credentials", withExtension: "plist")!
            
            let dict = NSDictionary(contentsOfFile: credentialsURL.relativePath) as! Dictionary<String, String>
            
            return dict["BsAPIPassword"]!
        }
        
        guard Bundle(url: Bundle(for: self).bundleURL.appendingPathComponent("BluesnapSDK_BluesnapSDK.bundle"))?.url(forResource: "credentials", withExtension: "plist") == nil else {
            let credentialsURL = Bundle(url: Bundle(for: self).bundleURL.appendingPathComponent("BluesnapSDK_BluesnapSDK.bundle"))!.url(forResource: "credentials", withExtension: "plist")!
            let dict = NSDictionary(contentsOfFile: credentialsURL.relativePath) as! Dictionary<String, String>
            
            return dict["BsAPIPassword"]!
        }
        
        /*guard Bundle(url: Bundle(for: self).bundleURL.appending(component: "BluesnapSDK_BluesnapSDK.bundle"))?.url(forResource: "credentials", withExtension: "plist") == nil else {
            let credentialsURL = Bundle(url: Bundle(for: self).bundleURL.appending(component: "BluesnapSDK_BluesnapSDK.bundle"))!.url(forResource: "credentials", withExtension: "plist")!
            let dict = NSDictionary(contentsOfFile: credentialsURL.relativePath) as! Dictionary<String, String>
            
            return dict["BsAPIPassword"]!
        }*/
        
        guard let credentialsURL = Bundle(for: self).url(forResource: "credentials", withExtension: "plist"),
              let dict = NSDictionary(contentsOfFile: credentialsURL.relativePath) as? Dictionary<String, String>
        else {
            return "PASSWORD_UNDEFINED"
        }
        
        return dict["BsAPIPassword"]!
    }
    
    internal static let BS_SANDBOX_DOMAIN = "https://sandbox.bluesnap.com/services/2/"
    internal static let BS_SANDBOX_TEST_USER = bsAPIUser
    internal static let BS_SANDBOX_TEST_PASSWORD = bsAPIPassword
    internal static let BS_SANDBOX_VAULTED_SHOPPER = "vaulted-shoppers"
    internal static let BS_SANDBOX_PLAN = "recurring/plans"
    internal static let BS_SANDBOX_SUBSCRIPTION = "recurring/subscriptions"
    
    static func createToken(shopperId: Int?, completion: @escaping (BSToken?, BSErrors?) -> Void) {
        createSandboxBSToken(shopperId: shopperId, completion: { bsToken, bsError in
            
            do {
                try BlueSnapSDK.setBsToken(bsToken: bsToken)
                completion(bsToken, bsError)
            } catch {
                NSLog("createToken, Unexpected error: \(error).")
            }
        })
    }

    static func createToken(completion: @escaping (BSToken?, BSErrors?) -> Void) {
        createToken(shopperId: nil, completion: completion)
    }

    /**
     Get BlueSnap Token from BlueSnap server
     Normally you will not do this from the app.

     - parameters:
     - user: username
     - password: password
     - completion: callback function for after the token is created; recfeives optional token and optional error
     */
    static func createSandboxBSToken(shopperId: Int?, completion: @escaping (BSToken?, BSErrors?) -> Void) {

        let domain: String = BS_SANDBOX_DOMAIN

        // create request
        var urlStr = domain + "payment-fields-tokens"
        if let shopperId = shopperId {
            urlStr = urlStr + "?shopperId=\(shopperId)"
        }
        let url = NSURL(string: urlStr)!
        var request = getURLRequest(urlStr: urlStr, httpMethod: "POST", contentType: "text/xml")

        // fire request

        var result: BSToken?
        var resultError: BSErrors?
        NSLog("BlueSnap; createSandboxBSToken")
        let task = URLSession.shared.dataTask(with: request as URLRequest) { (data, response, error) in
            NSLog("BlueSnap; createSandboxBSToken completion")
            if let error = error {
                let errorType = type(of: error)
                NSLog("error getting BSToken - \(errorType). Error: \(error.localizedDescription)")
                resultError = .unknown
            } else {
                let httpResponse = response as? HTTPURLResponse
                if let httpStatusCode: Int = (httpResponse?.statusCode) {
                    if (httpStatusCode >= 200 && httpStatusCode <= 299) {
                        result = self.extractTokenFromResponse(httpResponse: httpResponse)
                        if let result = result {
                            NSLog("createSandboxBSToken result")
                        } else {
                            resultError = .unknown
                        }
                    } else if (httpStatusCode >= 400 && httpStatusCode <= 499) {
                        NSLog("Http error getting BSToken; http status = \(httpStatusCode)")
                        resultError = .invalidInput
                    } else {
                        resultError = .unknown
                        NSLog("Http error getting BSToken; http status = \(httpStatusCode)")
                    }
                } else {
                    resultError = .unknown
                    NSLog("Http error getting response for BSToken")
                }
            }
            do {
                completion(result, resultError)
            }
        }
        task.resume()
    }


    static private func extractTokenFromResponse(httpResponse: HTTPURLResponse?) -> BSToken? {

        var result: BSToken?
        if let location: String = httpResponse?.allHeaderFields["Location"] as? String {
            if let lastIndexOfSlash = location.range(of: "/", options: String.CompareOptions.backwards, range: nil, locale: nil) {
                let tokenStr = String(location[lastIndexOfSlash.upperBound..<location.endIndex])
                do {
                    try result = BSToken(tokenStr: tokenStr)
                } catch {
                    NSLog("Unexpected error: \(error).")
                }
            } else {
                NSLog("Error: BS Token does not contain /")
            }
        } else {
            NSLog("Error: BS Token does not appear in response headers")
        }
        return result
    }

    /**
     Here all the data is on the token, we only need to send amount and currency
     */
    static func createTokenizedTransaction(
        purchaseDetails: BSBaseSdkResult!,
        bsToken: BSToken!,
        completion: @escaping (_ isSuccess: Bool, _ data: String?, _ shopperId: String?)->Void) {
        
        var responseData: Data!
        var requestBody = [
            "amount": "\(purchaseDetails.getAmount()!)",
            "recurringTransaction": "ECOMMERCE",
            "softDescriptor": "MobileSDKtest",
            "currency": "\(purchaseDetails.getCurrency()!)",
            "cardTransactionType": "AUTH_CAPTURE",
            "pfToken": "\(bsToken.getTokenStr()!)",
            ] as [String : Any]
        print("requestBody= \(requestBody)")
        let authorization = getBasicAuth()
        
        let urlStr = bsToken.getServerUrl() + "services/2/transactions";
        let url = NSURL(string: urlStr)!
        var request = NSMutableURLRequest(url: url as URL)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(authorization, forHTTPHeaderField: "Authorization")
        request.httpMethod = "POST"
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: .prettyPrinted)
        } catch let error {
            NSLog("Error serializing CC details: \(error.localizedDescription)")
        }
        
        // fire request
        
        var result : (isSuccess:Bool, data: String?, shopperId: String?) = (isSuccess:false, data: nil, shopperId: nil)
        
        let task = URLSession.shared.dataTask(with: request as URLRequest) { (data, response, error) in
            if let error = error {
                NSLog("error calling create transaction: \(error.localizedDescription)")
            } else {
                let httpResponse = response as? HTTPURLResponse
                if let httpStatusCode:Int = (httpResponse?.statusCode) {
                    
                    if let data = data {
                        responseData = data
                        result.data = String(data: data, encoding: .utf8)
                        NSLog("Response body = \(result.data ?? "")")
                    }
                    if (httpStatusCode >= 200 && httpStatusCode <= 299) {
                        do {
                            if let json = try JSONSerialization.jsonObject(with: responseData, options: .allowFragments) as? [String: AnyObject] {
                                //Extract shopper ID from transaction API response
                                result.shopperId = String(json["vaultedShopperId"] as! Int)
                                result.isSuccess = true
                            }
                        } catch let error as NSError {
                            NSLog("Error parsing BS result on Retrieve vaulted shopper: \(error.localizedDescription)")
                        }
                        
                    } else {
                        NSLog("Http error Creating BS Transaction; HTTP status = \(httpStatusCode)")
                    }
                }
            }
            do {
                DispatchQueue.main.async {
                    completion(result.isSuccess, result.data, result.shopperId)
                }
            }
        }
        task.resume()
    }
    
    static func createVaultedShopper(fullBilling: Bool, withEmail: Bool, withShipping: Bool, billingInfo: BSBillingAddressDetails? = nil, shippingInfo: BSShippingAddressDetails? = nil, creditCard: (Int, Int, String, String), completion: @escaping (String?, BSErrors?) -> Void) {
        
        // create request
        let urlStr = BS_SANDBOX_DOMAIN + BS_SANDBOX_VAULTED_SHOPPER
        let url = NSURL(string: urlStr)!
        
        

        let requestBody = createVaultedShopperDataObject(fullBilling: fullBilling, withEmail: withEmail, withShipping: withShipping, billingInfo: billingInfo, shippingInfo: shippingInfo, creditCard: creditCard)
    
        var request = getURLRequest(urlStr: urlStr, httpMethod: "POST", contentType: "application/json", requestBody: requestBody)
        
        
        // fire request
        var responseData: Data!
        var result: String?
        var resultError: BSErrors?
        let task = URLSession.shared.dataTask(with: request as URLRequest) { (data, response, error) in
            if let error = error {
                let errorType = type(of: error)
                NSLog("error creating Vaulted Shopper - \(errorType). Error: \(error.localizedDescription)")
                resultError = .unknown
            } else {
                let httpResponse = response as? HTTPURLResponse
                if let httpStatusCode: Int = (httpResponse?.statusCode) {
                    print("httpStatusCode= \(httpStatusCode)")
                    if let data = data {
                        responseData = data
                        let stringData = String(data: data, encoding: .utf8)
                        NSLog("Response body = \(stringData!))")
                    }
                    if (httpStatusCode >= 200 && httpStatusCode <= 299) {
                        do {
                            if let json = try JSONSerialization.jsonObject(with: responseData, options: .allowFragments) as? [String: AnyObject] {
                                //Extract shopper ID from transaction API response
                                result = String(json["vaultedShopperId"] as! Int)
                            }
                            
                        } catch let error as NSError {
                            NSLog("Error parsing BS response on Create Vaulted Shopper: \(error.localizedDescription)")
                        }
                        
                    } else if (httpStatusCode >= 400 && httpStatusCode <= 499) {
                        NSLog("Http error getting BSToken; http status = \(httpStatusCode)")
                        resultError = .invalidInput
                    } else {
                        resultError = .unknown
                        NSLog("Http error getting BSToken; http status = \(httpStatusCode)")
                    }
                } else {
                    resultError = .unknown
                    NSLog("Http error getting response for BSToken")
                }
            }
            do {
                completion(result, resultError)
            }
        }
        task.resume()
    }
    
    private static func createVaultedShopperDataObject(fullBilling: Bool, withEmail: Bool, withShipping: Bool, billingInfo: BSBillingAddressDetails? = nil, shippingInfo: BSShippingAddressDetails? = nil, creditCard: (Int, Int, String, String)) -> [String : Any]{
        
        // parse cc to requestBody
        let (firstName, lastName) = billingInfo?.getSplitName() ?? ("","")

        var requestBody = [
            "firstName" : firstName,
            "lastName" : lastName
            ] as [String : Any]
        
        // parse billing info to requestBody
        if let billingInfo_ = billingInfo {
            if (withEmail){
                requestBody["email"] = billingInfo_.email
            }
            
            let creditCard = [
                "expirationYear": creditCard.0,
                "securityCode": creditCard.1,
                "expirationMonth": creditCard.2,
                "cardNumber": creditCard.3
                ] as [String : Any]
            
            var billingContactInfo : [String : Any] = [:]
            
            billingContactInfo["firstName"] = firstName
            billingContactInfo["lastName"] = lastName
            billingContactInfo["zip"] = billingInfo_.zip
            billingContactInfo["country"] = billingInfo_.country
            
            if (fullBilling){
                billingContactInfo["address1"] = billingInfo_.address
                billingContactInfo["city"] = billingInfo_.city
                billingContactInfo["state"] = billingInfo_.state
            }
            
            requestBody["paymentSources"] = ["creditCardInfo" : [[
                "creditCard": creditCard,
                "billingContactInfo" : billingContactInfo
                ]]]
        }
        
        // parse shipping info to requestBody
        if (withShipping) {
            if let shippingInfo_ = shippingInfo {

                let (shippingFirstName, shippingLastName) = shippingInfo_.getSplitName()!

                var shippingContactInfo: [String: Any] = [:]
                shippingContactInfo["firstName"] = shippingFirstName
                shippingContactInfo["lastName"] = shippingLastName
                shippingContactInfo["country"] = shippingInfo_.country
                shippingContactInfo["zip"] = shippingInfo_.zip
                shippingContactInfo["address1"] = shippingInfo_.address
                shippingContactInfo["city"] = shippingInfo_.city
                shippingContactInfo["state"] = shippingInfo_.state

                requestBody["shippingContactInfo"] = shippingContactInfo
            }
        }
        
        print("requestBody= \(requestBody)")
        return requestBody
    }
    
    /**
     Get shopper information from BlueSnap server by a shopper Id
     Normally you will not do this from the app.

     - parameters:
     - shopperId: shopper Id
     - completion: callback function for after the call returns; receives optional token and optional error
     */
    static func retrieveVaultedShopper(
        vaultedShopperId shopperId: String,
        completion: @escaping (_ isSuccess: Bool, _ data: Data?)->Void) {

        print("shopperId= \(shopperId)")
        let authorization = getBasicAuth()

        let urlStr = BS_SANDBOX_DOMAIN + BS_SANDBOX_VAULTED_SHOPPER + "/" + shopperId;
        let url = NSURL(string: urlStr)!

        var request = getURLRequest(urlStr: urlStr, httpMethod: "GET", contentType: "application/json")

        var result : (isSuccess:Bool, data: Data?) = (isSuccess:false, data: nil)

        let task = URLSession.shared.dataTask(with: request as URLRequest) { (data, response, error) in
            if let error = error {
                NSLog("error in calling retrieve vaulted shopper: \(error.localizedDescription)")
            } else {
                let httpResponse = response as? HTTPURLResponse
                if let httpStatusCode:Int = (httpResponse?.statusCode) {

                    if let data = data {
                        result.data = data
                        let StringData = String(data: data, encoding: .utf8)
                        NSLog("RetrieveVaultedShopper Response body = \(StringData ?? "")")
                    }
                    if (httpStatusCode >= 200 && httpStatusCode <= 299) {
                        result.isSuccess = true
                    } else {
                        NSLog("Http error Creating BS Transaction; HTTP status = \(httpStatusCode)")
                    }
                }
            }
            defer {
                completion(result.isSuccess, result.data)
            }
        }
        task.resume()
    }
    
    static func createSubscriptionPlan(amount: Double, currency: String, trialPeriodDays: Int?, completion: @escaping (_ isSuccess: Bool, _ data: String?, _ planId: String?)->Void) {
        
        // create request
        let urlStr = BS_SANDBOX_DOMAIN + BS_SANDBOX_PLAN
        let url = NSURL(string: urlStr)!
        
        let requestBody = createBasicSubscriptionPlanDataObject(amount: amount, currency: currency, trialPeriodDays: trialPeriodDays)
        
        var request = getURLRequest(urlStr: urlStr, httpMethod: "POST", contentType: "application/json", requestBody: requestBody)
        
        // fire request
        
        var result : (isSuccess:Bool, data: String?, planId: String?) = (isSuccess:false, data: nil, planId: nil)
        var responseData: Data!

        let task = URLSession.shared.dataTask(with: request as URLRequest) { (data, response, error) in
            if let error = error {
                NSLog("error calling create transaction: \(error.localizedDescription)")
            } else {
                let httpResponse = response as? HTTPURLResponse
                if let httpStatusCode:Int = (httpResponse?.statusCode) {
                    
                    if let data = data {
                        responseData = data
                        result.data = String(data: data, encoding: .utf8)
                        NSLog("Response body = \(result.data ?? "")")
                    }
                    if (httpStatusCode >= 200 && httpStatusCode <= 299) {
                        do {
                            if let json = try JSONSerialization.jsonObject(with: responseData, options: .allowFragments) as? [String: AnyObject] {
                                //Extract plan ID from transaction API response
                                result.planId = String(json["planId"] as! Int)
                                result.isSuccess = true
                            }
                        } catch let error as NSError {
                            NSLog("Error parsing BS result on Retrieve vaulted shopper: \(error.localizedDescription)")
                        }
                        
                    } else {
                        NSLog("Http error Creating BS Transaction; HTTP status = \(httpStatusCode)")
                    }
                }
            }
            defer {
           DispatchQueue.main.async {
                    completion(result.isSuccess, result.data, result.planId)
                }
            }
        }
        task.resume()
    }
    
    private static func createBasicSubscriptionPlanDataObject(amount: Double, currency: String, trialPeriodDays: Int?) -> [String : Any]{
        
        var requestBody = [
            "chargeFrequency" : "MONTHLY",
            "name" : "Gold Plan",
            "currency" : currency,
            "recurringChargeAmount" : amount
            ] as [String : Any]
        
        if let trialPeriodDays = trialPeriodDays {
            requestBody["trialPeriodDays"] = trialPeriodDays
        }

        return requestBody
    }
    
    static func createSubscriptionCharge(planId: String, bsToken: BSToken?, completion: @escaping (_ isSuccess: Bool, _ data: String?, _ shopperId: String?)->Void) {
        
        // create request
        let urlStr = BS_SANDBOX_DOMAIN + BS_SANDBOX_SUBSCRIPTION
        let url = NSURL(string: urlStr)!
        
        let requestBody = createBasicSubscriptionChargeDataObject(planId: planId, bsToken: bsToken)
        
        var request = getURLRequest(urlStr: urlStr, httpMethod: "POST", contentType: "application/json", requestBody: requestBody)
        
        // fire request
        
        var result : (isSuccess:Bool, data: String?, shopperId: String?) = (isSuccess:false, data: nil, shopperId: nil)
        var responseData: Data!
        
        let task = URLSession.shared.dataTask(with: request as URLRequest) { (data, response, error) in
            if let error = error {
                NSLog("error calling create transaction: \(error.localizedDescription)")
            } else {
                let httpResponse = response as? HTTPURLResponse
                if let httpStatusCode:Int = (httpResponse?.statusCode) {
                    
                    if let data = data {
                        responseData = data
                        result.data = String(data: data, encoding: .utf8)
                        NSLog("Response body = \(result.data ?? "")")
                    }
                    if (httpStatusCode >= 200 && httpStatusCode <= 299) {
                        do {
                            if let json = try JSONSerialization.jsonObject(with: responseData, options: .allowFragments) as? [String: AnyObject] {
                                //Extract shopper ID from transaction API response
                                result.shopperId = String(json["vaultedShopperId"] as! Int)
                                result.isSuccess = true
                            }
                        } catch let error as NSError {
                            NSLog("Error parsing BS result on Retrieve vaulted shopper: \(error.localizedDescription)")
                        }
                        
                    } else {
                        NSLog("Http error Creating BS Transaction; HTTP status = \(httpStatusCode)")
                    }
                }
            }
            defer {
           DispatchQueue.main.async {
                    completion(result.isSuccess, result.data, result.shopperId)
                }
            }
        }
        task.resume()
    }
    
    private static func createBasicSubscriptionChargeDataObject(planId: String, bsToken: BSToken?) -> [String : Any]{
        
        let requestBody = [
            "planId" : planId,
            "paymentSource" : [
                "pfToken" : bsToken?.getTokenStr()
            ]] as [String : Any]
        
        
        return requestBody
    }

    /**
     Build the basic authentication header from username/password
     - parameters:
     - user: username
     - password: password
     */
    static private func getBasicAuth(user: String!, password: String!) -> String {
        let loginStr = String(format: "%@:%@", user, password)
        let loginData = loginStr.data(using: String.Encoding.utf8)!
        let base64LoginStr = loginData.base64EncodedString()
        return "Basic \(base64LoginStr)"
    }

    /**
     Build the basic authentication header from username/password
     */
    static private func getBasicAuth() -> String {
        return getBasicAuth(user: DemoAPIHelper.BS_SANDBOX_TEST_USER, password: DemoAPIHelper.BS_SANDBOX_TEST_PASSWORD)
    }

    /**
     Build a basic URL Request
     - parameters:
     - urlStr: url
     - httpMethod: operationt type to request
     - ContentType: content type of the request
     */
    static private func getURLRequest(urlStr: String, httpMethod: String, contentType: String, requestBody: Any? = nil) -> NSMutableURLRequest {
        let authorization = getBasicAuth()
        let url = NSURL(string: urlStr)!
        let request = NSMutableURLRequest(url: url as URL)
        request.httpMethod = httpMethod
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        request.setValue(authorization, forHTTPHeaderField: "Authorization")
        //request.setValue("0", forHTTPHeaderField: "Content-Length")
        if let requestBody = requestBody {
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: .prettyPrinted)
            } catch let error {
                NSLog("Error serializing request body: \(error.localizedDescription)")
            }
        }
        return request

    }

    public enum MockBSErrors : Int {

        // CC
        case invalidCcNumber
        case invalidCvv
        case invalidExpDate

        // ApplePay
        case cantMakePaymentError
        case applePayOperationError
        case applePayCanceled

        // PayPal
        case paypalUnsupportedCurrency
        case paypalUTokenAlreadyUsed

        // generic
        case invalidInput
        case expiredToken
        case cardTypeNotSupported
        case tokenNotFound
        case tokenAlreadyUsed
        case unAuthorised
        case unknown

        public func description() -> String {
            switch self {

            case .invalidCcNumber:
                return "invalidCcNumber";
            case .invalidCvv:
                return "invalidCvv";
            case .invalidExpDate:
                return "invalidExpDate";

            case .cantMakePaymentError:
                return "cantMakePaymentError";
            case .applePayOperationError:
                return "applePayOperationError";
            case .applePayCanceled:
                return "applePayCanceled";

            case .paypalUnsupportedCurrency:
                return "paypalUnsupportedCurrency";

            case .invalidInput:
                return "invalidInput";
            case .expiredToken:
                return "expiredToken";
            case .cardTypeNotSupported:
                return "cardTypeNotSupported";
            case .tokenNotFound:
                return "tokenNotFound";
            case .tokenAlreadyUsed:
                return "tokenAlreadyUsed";
            case .unAuthorised:
                return "unAuthorised";

            default:
                return "unknown";
            }
        }

    }


}
