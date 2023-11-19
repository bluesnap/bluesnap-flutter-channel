package com.sdk.bluesnap_sdk.utils


import android.os.Bundle
import com.bluesnap.androidapi.views.activities.BluesnapCheckoutActivity
import com.sdk.bluesnap_sdk.models.CheckoutCardProps
import com.google.gson.GsonBuilder

val GSON_MAPPER = GsonBuilder().serializeNulls().create()
class DataConverter {
    companion object {

        private fun <Any> toMap(obj: Any):  Map<String, Any?>  {
            val ktMap = GSON_MAPPER.fromJson(GSON_MAPPER.toJson(obj), Map::class.java)
            val map = HashMap<String, Any?>()

            for (key in ktMap.keys) {
                val data = ktMap[key]
                val keyStr = key.toString()

                when (data) {
                    null -> map[keyStr] = null
                    is Int -> map[keyStr] = data as Any
                    is Double -> map[keyStr] = data as Any
                    is String -> map[keyStr] = data as Any
                    is Boolean -> map[keyStr] = data as Any
                    is Map<*, *> -> map[keyStr] = data as Any
                    is List<*> -> map[keyStr] = data as Any
                    is Array<*> -> map[keyStr] = data as Any
                    else -> {
                     val mapData =  toMap(data)
                        map[keyStr] = mapData as Any
                    }
                }
            }

            return map
        }

        fun checkoutResultBundleToMap(obj: Bundle): Map<String, Any?> {
            val map = HashMap<String, Any?>()
            for (key in obj.keySet()) {
                if (key is String) {
                    val data = obj.get(key)
                    val keyStr = when (key) {
                        BluesnapCheckoutActivity.EXTRA_BILLING_DETAILS -> "billingDetails"
                        BluesnapCheckoutActivity.EXTRA_PAYMENT_RESULT -> "paymentInfo"
                        else -> key.toString()
                    }
                    map[keyStr] = data


                    when (data) {
                        null ->    map[keyStr] = null
                        is Int -> map[keyStr] = data
                        is Double -> map[keyStr] = data
                        is String -> map[keyStr] = data
                        is Boolean -> map[keyStr] = data
                        is HashMap<*, *> -> map[keyStr] = data
                        is List<*> -> map[keyStr] = data
                        is Array<*> -> map[keyStr] = data
                        else -> map[keyStr] = toMap(data )
                    }
                }
            }
            return map
        }

        fun toCheckoutCardProps(map: Map<String,Any?>): CheckoutCardProps {
            val cardNumber: String = when (map.containsKey("cardNumber")) {
                true -> map["cardNumber"].toString()
                else -> ""
            }
            val expirationDate = when (map.containsKey("expirationDate")) {
                true -> map["expirationDate"].toString()
                else -> ""
            }
            val cvv = when (map.containsKey("cvv")) {
                true -> map["cvv"].toString()
                else -> ""
            }
            val name = when (map.containsKey("name")) {
                true -> map["name"].toString()
                else -> ""
            }
            val billingZip = when (map.containsKey("billingZip")) {
                true -> map["billingZip"].toString()
                else -> ""
            }
            val isStoreCard = when (map.containsKey("isStoreCard")) {
                true -> map["isStoreCard"]
                else -> false
            }
            val email = when (map.containsKey("email")) {
                true -> map["email"]
                else -> null
            }

            return CheckoutCardProps(cardNumber, expirationDate, cvv, name, billingZip, isStoreCard as Boolean, email as String?)
        }
    }
}
