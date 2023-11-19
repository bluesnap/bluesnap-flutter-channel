package com.sdk.bluesnap_sdk

import android.app.Activity
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.annotation.NonNull
import com.bluesnap.androidapi.http.BlueSnapHTTPResponse
import com.bluesnap.androidapi.models.BillingContactInfo
import com.bluesnap.androidapi.models.CreditCard
import com.bluesnap.androidapi.models.CreditCardInfo
import com.bluesnap.androidapi.models.PurchaseDetails
import com.bluesnap.androidapi.models.SdkRequest
import com.bluesnap.androidapi.models.SdkRequestBase
import com.bluesnap.androidapi.models.SdkRequestShopperRequirements
import com.bluesnap.androidapi.models.SdkResult
import com.bluesnap.androidapi.models.Shopper
import com.bluesnap.androidapi.models.SupportedPaymentMethods
import com.bluesnap.androidapi.services.BSPaymentRequestException
import com.bluesnap.androidapi.services.BlueSnapLocalBroadcastManager
import com.bluesnap.androidapi.services.BlueSnapService
import com.bluesnap.androidapi.services.BluesnapAlertDialog
import com.bluesnap.androidapi.services.BluesnapServiceCallback
import com.bluesnap.androidapi.services.CardinalManager
import com.bluesnap.androidapi.services.KountService
import com.bluesnap.androidapi.services.TaxCalculator
import com.bluesnap.androidapi.services.TokenProvider
import com.bluesnap.androidapi.services.TokenServiceCallback
import com.bluesnap.androidapi.views.activities.BluesnapCheckoutActivity
import com.bluesnap.androidapi.views.activities.BluesnapCheckoutActivity.REQUEST_CODE_DEFAULT
import com.sdk.bluesnap_sdk.utils.AwaitLock
import com.sdk.bluesnap_sdk.utils.DataConverter
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import org.json.JSONArray
import org.json.JSONException
import org.json.JSONObject
import java.io.UnsupportedEncodingException
import java.net.HttpURLConnection


/** BluesnapSdkPlugin */
open class BluesnapSdkPlugin: FlutterPlugin, MethodCallHandler,
ActivityAware, PluginRegistry.ActivityResultListener {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel: MethodChannel
  private val TAG = "FlutterBluesnapPlugin"

  // protected FlutterPluginBinding binding
  private var bluesnapService: BlueSnapService? = null
  private var tokenProvider: TokenProvider? = null
  private var methodChannel: MethodChannel? = null

  //  protected var token: String? = null
//  protected  var currency:String? = null
//  protected var enableGooglePay: Boolean? = null
//  protected  var enablePaypal:Boolean? = null
//  protected  var enableProduction:Boolean? = null
//  protected  var disable3DS:Boolean? = null
//  protected var applicationContext: Context? = null
  private var activity: Activity? = null
  private var merchantToken: String? = null
  private var awaitLockScope: CoroutineScope
  private var purchaseLock: AwaitLock? = null
  private var tokenGenerationLock: AwaitLock? = null
  private var sdkRequest: SdkRequestBase? = null
  private var shopperId: Int? = null

  init {
    this.purchaseLock = AwaitLock()
    this.tokenGenerationLock = AwaitLock()
    this.awaitLockScope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
//    reactContext?.addActivityEventListener(mActivityEventListener)
    bluesnapService = BlueSnapService.getInstance()
  }

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "bluesnap_sdk")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
      "initBluesnap" -> {
        val argumentsMap = call.arguments as? Map<*, *>
        initBluesnap(
          bsToken = argumentsMap?.get("bsToken") as String?,
          initKount = (argumentsMap?.get("initKount") ?: false) as Boolean,
          fraudSessionId = argumentsMap?.get("fraudSessionId") as String?,
          applePayMerchantIdentifier = argumentsMap?.get("applePayMerchantIdentifier") as String?,
          merchantStoreCurrency = argumentsMap?.get("merchantStoreCurrency") as String?,
          result = result
        )
      }

      "setSDKRequest" -> {
        val argumentsMap = call.arguments as? Map<*, *>
        setSDKRequest(
          withEmail = (argumentsMap?.get("withEmail") ?: false) as Boolean,
          withShipping = (argumentsMap?.get("withShipping") ?: false) as Boolean,
          fullBilling = (argumentsMap?.get("fullBilling") ?: false) as Boolean,
          amount = (argumentsMap?.get("amount") ?: false) as Double,
          taxAmount = (argumentsMap?.get("taxAmount") ?: false) as Double,
          currency = (argumentsMap?.get("currency") ?: false) as String,
          activate3DS = (argumentsMap?.get("activate3DS") ?: false) as Boolean,
          result = result,
        )
      }

      "finalizeToken" -> {
        val token = call.arguments as? String
        finalizeToken(token, result)
      }

      "showCheckout" -> {
        showCheckout(result = result)
      }

      "checkoutCard" -> {
        val argumentsMap = call.arguments as? Map<*, *>
        checkoutCard(props = argumentsMap as Map<String, Any>,result = result)
      }
    }

//    setSDKRequest(
//      withEmail: Boolean,
//      withShipping: Boolean,
//      fullBilling: Boolean,
//      amount: Double,
//      taxAmount: Double,
//      currency: String,
//      activate3DS: Boolean
//    if (call.method == "getPlatformVersion") {
//      result.success("Android ${android.os.Build.VERSION.RELEASE}")
//    } else if (call.method == "getPlatformVersion") {
//      result.success("Android ${android.os.Build.VERSION.RELEASE}")
//    } else {
//      result.notImplemented()
//    }
  }

//  private fun sendMessageToDart(method: String) {
//    sendMessageToDart(method, null)
//  }
//
//  private fun sendMessageToDart(method: String, value: Any?) {
//    Handler(Looper.getMainLooper()).post { // Call the desired channel message here.
//      methodChannel?.invokeMethod(method, value, object : Result {
//        override fun success(result: Any?) {
//          Log.i(TAG, "Message sent successfully")
//        }
//
//        override fun error(
//          errorCode: String,
//          errorMessage: String?,
//          errorDetails: Any?
//        ) {
//          Log.e(TAG, "Method call failed: $errorMessage")
//        }
//
//        override fun notImplemented() {
//          Log.e(TAG, "Method not implemented in dart")
//        }
//      })
//    }
//  }


  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    activity = null
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
    binding.addActivityResultListener(this)
  }

  override fun onDetachedFromActivityForConfigChanges() {
    activity = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onDetachedFromActivity() {
    activity = null
  }


  /**
   *
   */

  fun initBluesnap(
    bsToken: String?,
    initKount: Boolean,
    fraudSessionId: String?,
    applePayMerchantIdentifier: String?,
    merchantStoreCurrency: String?,
    result: Result,
  ) {
    generateAndSetBsToken() { token, error ->
      Log.i(TAG, "generateAndSetBsToken $token $error")

      // create the interface for activating the token creation from server
      tokenProvider = TokenProvider { tokenServiceCallback ->
        if (error == null) {
          //change the expired token
          tokenServiceCallback.complete(token)
        } else { }
      }

      if (error == null) {
        //final String merchantStoreCurrency = (null == currency || null == currency.getCurrencyCode()) ? "USD" : currency.getCurrencyCode()
        activity?.let {

          try {
            bluesnapService?.setup(
              token,
              tokenProvider,
              merchantStoreCurrency,
              it,
              object : BluesnapServiceCallback {
                override fun onSuccess() {
                  activity?.runOnUiThread(Runnable {
                    result.success("Success")
                  })
                }

                override fun onFailure() {
                  activity?.runOnUiThread(Runnable {
                    result.error("error", "error", "error")
                  })
                }
              })
          }catch (e: Exception){
            result.error("error", e.message, e.message)
//            methodChannel?.invokeMethod("error", e.toString())
          }

        }
      } else {
        activity?.let {
          BluesnapAlertDialog.setDialog(
            it,
            "Cannot obtain token from merchant server",
            "Service error",
            object : BluesnapAlertDialog.BluesnapDialogCallback {
              override fun setPositiveDialog() {}

              override fun setNegativeDialog() {
                initBluesnap(
                  bsToken,
                  initKount,
                  fraudSessionId,
                  applePayMerchantIdentifier,
                  merchantStoreCurrency,
                  result
                )
              }
            },
            "Close",
            "Retry"
          )
        }
      }
    }
  }

  /**
   * Called by the BlueSnapSDK when token expired error is recognized.
   * Here we ask React Native to generate a new token, so that when the action re-tries, it will succeedbdtren.
   */
  private fun generateAndSetBsToken(completion: (token: String?, error: Any?) -> Unit) {
    Log.i(TAG, "generateAndSetBSToken, Got BS token expiration notification!")

    // Send an event to React Native, asking it to generate a token.
    val map = HashMap<String, Any?>()
    map["shopperID"] = shopperId

    channel.invokeMethod("generateToken", map)
//    sendEvent(reactApplicationContext, "generateToken", map)

    awaitLockScope.launch {
      // Wait for the React Native token generator to call `finalizeToken`.
      tokenGenerationLock?.startLock(3000)
    }

    awaitLockScope.launch {
      // This will run after `finalizeToken` was called.
      val result = tokenGenerationLock?.awaitLock() as String?
      Log.i(TAG, "tokenGeneration  Lockker $result")
      merchantToken = result
      if (result.isNullOrEmpty()) {
        completion(null, "Unknown")
      } else {
        completion(result, null)
      }
    }
  }

  /**
   *
   */
  private fun setSDKRequest(
    withEmail: Boolean,
    withShipping: Boolean,
    fullBilling: Boolean,
    amount: Double,
    taxAmount: Double,
    currency: String,
    activate3DS: Boolean,
    result: Result
  ) {
    this.sdkRequest = SdkRequest(
      amount,
      currency,
      fullBilling,
      withEmail,
      withShipping
    )
    this.sdkRequest?.isActivate3DS = activate3DS

    //FIXME: Android not support set `taxAmount` in constructor for now
    this.sdkRequest?.taxCalculator =
      TaxCalculator { shippingCountry, shippingState, priceDetails ->
        priceDetails.taxAmount = taxAmount
      }
    result.success(null)
  }


  /**
   *
   */

  private fun showCheckout(
    result: Result
  ) {
    var currentSdkRequest = sdkRequest
    if (currentSdkRequest == null) {
      currentSdkRequest = SdkRequestShopperRequirements()
      sdkRequest = currentSdkRequest
    }

    this.sdkRequest?.isGooglePayTestMode = true
    this.sdkRequest?.setGooglePayActive(true)

    try {
      currentSdkRequest.verify()
    } catch (e: BSPaymentRequestException) {
      Log.i(TAG, "showCheckout verify ${e.message}")
      Log.d(TAG, this.sdkRequest.toString())
      result.error("error_code", e.message, e.message)
    }

    // Set special tax policy: non-US pay no tax MA pays 10%, other US states pay 5%
    currentSdkRequest.taxCalculator =
      TaxCalculator { shippingCountry, shippingState, priceDetails ->
        if ("us".equals(shippingCountry, ignoreCase = true)) {
          var taxRate = 0.05
          if ("ma".equals(shippingState, ignoreCase = true)) {
            taxRate = 0.1
          }
          priceDetails.taxAmount = priceDetails.subtotalAmount * taxRate
        } else {
          priceDetails.taxAmount = 0.0
        }
      }

    try {
      bluesnapService?.sdkRequest = currentSdkRequest
      Log.i(TAG, "showCheckout bluesnapService")

      awaitLockScope.launch {
        purchaseLock?.startLock(3000)
      }

      val currentActivity = activity
      if (currentActivity == null) {
        result.error("error_code", "Activity null", "Activity null")
        return
      }

      val intent = Intent(currentActivity, BluesnapCheckoutActivity::class.java)
      currentActivity.startActivityForResult(intent, REQUEST_CODE_DEFAULT)

      awaitLockScope.launch {
        val purchaseResult = purchaseLock?.awaitLock()
        Log.i(TAG, "showCheckout result: $purchaseResult")

        if (purchaseResult != null) {
          result.success(DataConverter.checkoutResultBundleToMap(purchaseResult as Bundle))
        } else {
          result.error("error_code", "Error description", "Error description")
        }
      }
    } catch (e: Exception) {
      e.printStackTrace()
      result.error("error_code", "payment request not validated", e.message)
    }
  }

  /**
   * This function shall only be called from React Native when the token generator finishes generating a token.
   */
  private fun finalizeToken(token: String?, result: Result) {
    awaitLockScope.launch {
      if (token != null) {
        tokenGenerationLock?.stopLock(token)
      } else {
        tokenGenerationLock?.stopLock("")
      }
    }

    result.success(null)
  }

  /**
   * tokenize Card On Server,
   * receive shopper and activate api tokenization to the server according to SDK Request [com.bluesnap.androidapi.models.SdkRequest] spec
   *
   * @param shopper      - [Shopper]
   * @param promise - [Promise]
   * @throws UnsupportedEncodingException - UnsupportedEncodingException
   * @throws JSONException                - JSONException
   */
  @Throws(UnsupportedEncodingException::class, JSONException::class)
  private fun tokenizeCardOnServer(shopper: Shopper, result: Result) {
    if (bluesnapService == null) {
      result.error("error_code", "bluesnapService is null", "bluesnapService is null")
      return
    }

    val purchaseDetails = PurchaseDetails(
      shopper.newCreditCardInfo!!.creditCard,
      shopper.newCreditCardInfo!!.billingContactInfo,
      shopper.shippingContactInfo,
      shopper.isStoreCard
    )
    bluesnapService?.appExecutors?.networkIO()?.execute(Runnable {
      try {
        val response: BlueSnapHTTPResponse? =
          bluesnapService?.submitTokenizedDetails(purchaseDetails)
        if (response?.responseCode == HttpURLConnection.HTTP_OK) {
          if (sdkRequest!!.isActivate3DS) {
            cardinal3DS(purchaseDetails, shopper, result, response)
          } else {
            finishFromActivity(shopper, result, response)
          }
        } else if (response?.responseCode == 400 &&
          null != bluesnapService?.tokenProvider && "" != response.responseString
        ) {
          try {
            val errorResponse = JSONObject(response.responseString)
            val rs2 = errorResponse["message"] as JSONArray
            val rs3 = rs2[0] as JSONObject
            if ("EXPIRED_TOKEN" == rs3["errorName"]) {
              bluesnapService?.tokenProvider?.getNewToken(TokenServiceCallback { newToken ->
                bluesnapService?.setNewToken(newToken)
                try {
                  tokenizeCardOnServer(shopper, result)
                } catch (e: UnsupportedEncodingException) {
                  Log.e(TAG, "Unsupported Encoding Exception", e)
                  result.error("error_code", e.message, e.message)
                } catch (e: JSONException) {
                  Log.e(TAG, "json parsing exception")
                  result.error("error_code", e.message, e.message)
                }
              })
            } else {
              result.error("error_code", response.toString(), response.toString())
            }
          } catch (e: JSONException) {
            Log.e(TAG, "json parsing exception", e)
            result.error("error_code", e.message, e.message)
          }
        } else {
          result.error("error_code", response.toString(), response.toString())

        }
      } catch (e: JSONException) {
        Log.e(TAG, "JsonException")
        result.error("error_code", e.message, e.message)
      }
    })
  }

  private fun cardinal3DS(
    purchaseDetails: PurchaseDetails,
    shopper: Shopper,
    result: Result,
    response: BlueSnapHTTPResponse
  ) {

    // Request auth with 3DS
    val cardinalManager = CardinalManager.getInstance()
    val broadcastReceiver: BroadcastReceiver = object : BroadcastReceiver() {
      override fun onReceive(context: Context, intent: Intent) {
        Log.d(TAG, "Got broadcastReceiver intent")
        if (cardinalManager.threeDSAuthResult == CardinalManager.ThreeDSManagerResponse.AUTHENTICATION_CANCELED.name) {
          Log.d(TAG, "Cardinal challenge canceled")
          //FIXME
//          progressBar.setVisibility(View.INVISIBLE)
//          runOnUiThread {
//            BluesnapAlertDialog.setDialog(
//              this@CreditCardActivity,
//              "3DS Authentication is required",
//              ""
//            )
//          }
        } else if (cardinalManager.threeDSAuthResult == CardinalManager.ThreeDSManagerResponse.AUTHENTICATION_FAILED.name || cardinalManager.threeDSAuthResult == CardinalManager.ThreeDSManagerResponse.THREE_DS_ERROR.name) { //cardinal internal error or authentication failure

          // TODO: Change this after receiving "proceed with/without 3DS" from server in init API call
//          val error = intent.getStringExtra(CardinalManager.THREE_DS_AUTH_DONE_EVENT_TAG)
          val error = intent.getStringExtra(CardinalManager.THREE_DS_AUTH_DONE_EVENT_NAME)
          result.error("error_code", error, error)
        } else { //cardinal success (success/bypass/unavailable/unsupported)
          Log.d(TAG, "3DS Flow ended properly")
          finishFromActivity(shopper, result, response)
        }
      }
    }
    BlueSnapLocalBroadcastManager.registerReceiver(
      activity,
      CardinalManager.THREE_DS_AUTH_DONE_EVENT,
      broadcastReceiver
    )
    try {
      cardinalManager?.authWith3DS(
        this.sdkRequest?.priceDetails?.currencyCode,
        this.sdkRequest?.priceDetails?.amount,
        activity,
        purchaseDetails.creditCard
      )
    } catch (e: JSONException) {
      Log.d(TAG, "Error in parsing authWith3DS API response")
      result.error(
        "error_code",
        "Error in parsing authWith3DS API response",
        "Error in parsing authWith3DS API response"
      )
    }
  }

  /**
   * 3DS flow
   */
  private fun finishFromActivity(
    shopper: Shopper,
    result: Result,
    response: BlueSnapHTTPResponse
  ) {
    try {
      val Last4: String
      val ccType: String?
      val sdkResult = BlueSnapService.getInstance().sdkResult
      if (shopper.newCreditCardInfo!!.creditCard.isNewCreditCard) {
        // New Card
        val jsonObject = JSONObject(response.responseString)
        Last4 = jsonObject.getString("last4Digits")
        ccType = jsonObject.getString("ccType")
        Log.d(TAG, "tokenization of new credit card")
      } else {
        // Reused Card
        Last4 = shopper.newCreditCardInfo!!.creditCard.cardLastFourDigits
        ccType = shopper.newCreditCardInfo!!.creditCard.cardType
        Log.d(TAG, "tokenization of previous used credit card")
      }
      sdkResult.billingContactInfo = shopper.newCreditCardInfo!!.billingContactInfo
      if (sdkRequest!!.shopperCheckoutRequirements.isShippingRequired) sdkResult.shippingContactInfo =
        shopper.shippingContactInfo
      sdkResult.kountSessionId = KountService.getInstance().kountSessionId
      sdkResult.token = BlueSnapService.getInstance().blueSnapToken.merchantToken
      // update last4 from server result
      sdkResult.last4Digits = Last4
      // update card type from server result
      sdkResult.cardType = ccType
      sdkResult.chosenPaymentMethodType = SupportedPaymentMethods.CC
      sdkResult.threeDSAuthenticationResult = CardinalManager.getInstance().threeDSAuthResult
      val bundle = Bundle()
      bundle.putParcelable(BluesnapCheckoutActivity.EXTRA_PAYMENT_RESULT, sdkResult)
      bundle.putParcelable(
        BluesnapCheckoutActivity.EXTRA_BILLING_DETAILS,
        shopper.newCreditCardInfo?.billingContactInfo
      )
      //Only set the remember shopper here since failure can lead to missing tokenization on the server
      shopper.newCreditCardInfo!!.creditCard.setTokenizationSuccess()
      result.success(DataConverter.checkoutResultBundleToMap(bundle))
      Log.d(TAG, "tokenization finished")
    } catch (e: NullPointerException) {
      result.error("error_code", e.message, e.message)
    } catch (e: JSONException) {
      result.error("error_code", e.message, e.message)
    }
  }

  /**
   *
   */

 private fun checkoutCard(
    props: Map<String, Any>,
    result: Result
  ) {
    val checkoutProps = DataConverter.toCheckoutCardProps(props)
    Log.i(TAG, "checkoutCard start for card ${checkoutProps.cardNumber}")
    val shopper: Shopper? = bluesnapService?.getsDKConfiguration()?.shopper

    if (shopper != null) {
      //set credit card info
      val creditCard = CreditCard()
      creditCard.number = checkoutProps.cardNumber
      creditCard.setExpDateFromString(checkoutProps.expirationDate)
      creditCard.cvc = checkoutProps.cvv
      //set billing contact info
      val billingContactInfo = BillingContactInfo()
      billingContactInfo.fullName = checkoutProps.name
      billingContactInfo.zip = checkoutProps.billingZip
//      if (sdkRequest?.shopperCheckoutRequirements?.isEmailRequired == true) {
//        if (checkoutProps.email.isNullOrEmpty()) {
//          promise.reject("error_code", "Email is required")
//          return
//        }
//      }
      billingContactInfo.email = checkoutProps.email
      //FIXME: set address, city,...

      val creditCardInfo = CreditCardInfo()
      creditCardInfo.creditCard = creditCard
      creditCardInfo.billingContactInfo = billingContactInfo

      shopper.isStoreCard = checkoutProps.isStoreCard
      shopper.newCreditCardInfo = creditCardInfo

//      val resultIntent = Intent()

      try {
        tokenizeCardOnServer(shopper, result)
      } catch (e: Exception) {
        result.error("error_code", e.message, e.message)
      }
    } else {
      result.error("error_code", "Invalid shopper", "Invalid shopper")
    }
  }


   override  fun onActivityResult(requestCode: Int, resultCode: Int, intent: Intent?): Boolean {
//    var isSubscription = false
    if (resultCode != BluesnapCheckoutActivity.RESULT_OK) {
      awaitLockScope.launch {
        val resultBundle = Bundle()

        if (intent != null) {
          var sdkErrorMsg: String? = "SDK Failed to process the request: "
          sdkErrorMsg += intent.getStringExtra(BluesnapCheckoutActivity.SDK_ERROR_MSG)
          resultBundle.putString("errors", sdkErrorMsg)

        } else {
          resultBundle.putString("errors", "Purchase canceled")
        }
        purchaseLock?.stopLock(resultBundle)
      }

      return false
    }

    // Here we can access the payment result
    val extras = intent?.extras
    val sdkResult =
      intent?.getParcelableExtra<SdkResult>(BluesnapCheckoutActivity.EXTRA_PAYMENT_RESULT)

    if (BluesnapCheckoutActivity.BS_CHECKOUT_RESULT_OK == sdkResult?.result) {
      //Handle checkout result
      awaitLockScope.launch {
        purchaseLock?.stopLock(extras)
      }

    }
    //Recreate the demo activity
    merchantToken = null

    return false
  }



}
