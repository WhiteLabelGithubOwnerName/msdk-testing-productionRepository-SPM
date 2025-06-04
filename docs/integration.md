# Integration

- [Integration](#integration)
  - [Set up WalleeTest Checkout](#set-up-walleetestsdk)
  - [Create transaction](#create-transaction)
  - [Collect payment details](#collect-payment-details)
    - [Basic usage Swift (Storyboard)](#basic-usage-swift-storyboard)
    - [Basic usage SwiftUI](#basic-usage-swiftui)
  - [Handle result](#handle-result)
    - [Additional integration steps](#additional-integration-steps)
  - [Verify payment](#verify-payment)

## Set up WalleeTest Checkout

To use the iOS Payment SDK, you need a [WalleeTest Checkout account](https://checkout.postfinance.ch/user/signup). After signing up, set up your space and enable the payment methods you would like to support.

## Create transaction

For security reasons, your app cannot create transactions and fetch access tokens. This has to be done on your server by talking to the [WalleeTest Checkout Web Service API](https://checkout.postfinance.ch/en-us/doc/api/web-service). You can use one of the official SDK libraries to make these calls.

To use the iOS Payment SDK to collect payments, an endpoint needs to be added on your server that creates a transaction by calling the [create transaction](https://checkout.postfinance.ch/doc/api/web-service#transaction-service--create) API endpoint. A transaction holds information about the customer and the line items and tracks charge attempts and the payment state.

Once the transaction has been created, your endpoint can fetch an access token by calling the [create transaction credentials](https://checkout.postfinance.ch/doc/api/web-service#transaction-service--create-transaction-credentials) API endpoint. The access token is returned and passed to the iOS Payment SDK.

```bash
# Create a transaction
curl 'https://checkout.postfinance.ch/api/transaction/create?spaceId=1' \
  -X "POST" \
  -d "{{TRANSACTION_DATA}}"

# Fetch an access token for the created transaction
curl 'https://checkout.postfinance.ch/api/transaction/createTransactionCredentials?spaceId={{SPACE_ID}}&id={{TRANSACTION_ID}}' \
  -X 'POST'
```

## Collect payment details

### Basic usage Swift (Storyboard)

Before launching the iOS Payment SDK to collect the payment, your checkout page should show the total amount, the products that are being purchased and a checkout button to start the payment process.

Let your checkout activity extend `WalleeTestResultObserver`, add the necessary function `paymentResult`.

```swift
import UIKit
import WalleeTestSdk

class ViewController : UIViewController, WalleeTestResultObserver {

    func paymentResult(paymentResultMessage: PaymentResult)
    {
        ....
    }
}
```

When the customer taps the checkout button, call your endpoint that creates the transaction and returns the access token, initialize the `WalleeTestSdk` instance and launch the payment dialog.

```swift
// ...
import UIKit
import WalleeTestSdk

class ViewController : UIViewController, WalleeTestResultObserver {

    //...
    var paymentSdk: WalleeTestSdk

    @IBAction func openSdkClick()
    {
        paymentSdk = WalleeTestSdk(eventObserver: self)
        ...
        paymentSdk.launchPayment(token: _token)
    }

    // ...
}
```

After the customer completes the payment, the dialog dismisses and the `paymentResult` method is called.

### Basic usage SwiftUI

First of all make sure you import the `WalleeTestSdk` package and initialize it in relevant class. You also need to extend the class with `WalleeTestResultObserver` to able to receive the result of payment:

```swift
// PaymentManager.swift
import WalleeTestSdk
...
class PaymentManager: WalleeTestResultObserver {
...
func onOpenSdkPress(){
    let sdk = WalleeTestSdk(eventObserver: self)
    ...
    }
}
```

To display the UI of Payment SDK make sure you import the `WalleeTestSdk` into the relevant View:

```swift
// ContentView.swift
import WalleeTestSdk
...
    Button {
       // add code for generating transaction and fetching the token
       isModalPresented = true
    } label: {
        Text("Checkout")
    }
    .presentModalView(isPresented: isModalPresented, token: token)
```

Use presentModalView custom modifier for the UI part, passing two arguments: `isPresented` (modal presented state) and `token`.

## Handle result

The response object contains these properties:

- `code` describing the result's type.

| Code | Description |
| --- | --- |
| `COMPLETED` | The payment was successful. |
| `FAILED` | The payment failed. Check the `message` for more information. |
| `CANCELED` | The customer canceled the payment. |
| `PENDING` | The customer has aborted the payment process, so the payment is in a temporarily pending state. It will eventually reach a final status (successful or failed), but it may take a while. Wait for a webhook notification and use the WalleeTest Checkout API to retrieve the status of the transaction and inform the customer that the payment is pending. |
| `TIMEOUT` | Token for this transaction expired. App will be closed and third-party app will get this message. For opening payment sdk third party app have to refetch token |

- `message` providing a localized error message that can be shown to the customer.

```swift
import UIKit
import WalleeTestSdk

class ViewController: UIViewController, WalleeTestResultObserver {
    // ...

    @IBOutlet var resultCallbackText: UILabel?

    func paymentResult(paymentResultMessage: PaymentResult) {
        var colorCodeMap = [PaymentResultEnum.FAILED: UIColor.red, PaymentResultEnum.COMPLETED: UIColor.green, PaymentResultEnum.CANCELED: UIColor.orange]

        DispatchQueue.main.async {
            self.resultCallbackText?.text = paymentResultMessage.code.rawValue
            self.resultCallbackText?.textColor = colorCodeMap[paymentResultMessage.code];
        }
    }

    // ...
}
```

### Additional integration steps

`WalleeTestSdk.onHandleOpenURL(url: url)` Static function for handling deep link. It has to be called in [SceneDelegate](https://developer.apple.com/documentation/uikit/uiscenedelegate/3238059-scene) or [AppDelegate](https://developer.apple.com/documentation/uikit/uiapplicationdelegate/1623112-application?language=objc). Without this implementation SDK isn't able to send current response when transaction is complete.

```swift


class SceneDelegate: UIResponder, UIWindowSceneDelegate {

...

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        if let url = URLContexts.first?.url{
          WalleeTestSdk.onHandleOpenURL(url: url)
        }
    }
...

}

```

For Twint integration you have to setup `URL types` and `Queried URL Schemes` in your app `Info.plist` and pass deep link into SDK

```javascript

func foo(){
    let sdk = WalleeTestSdk(eventObserver: self)
    ...
    sdk.configureDeepLink(deepLink: "uniq-payment-deep-link")
    ...
}

```

<mark style="background-color: red"> :bangbang: :warning: Please note that this is essential to invoke TWINT. :warning: :bangbang: </mark>

```xml
 <key>CFBundleURLTypes</key>
 <array>
  <dict>
   <key>CFBundleTypeRole</key>
   <string>Editor</string>
   <key>CFBundleURLSchemes</key>
   <array>
    <string>uniq-payment-deep-link</string>
   </array>
  </dict>
 </array>
 <key>LSApplicationQueriesSchemes</key>
 <array>
    <string>twint-issuer1</string>
    <string>twint-issuer2</string>
    <string>twint-issuer3</string>
    <string>twint-issuer4</string>
    <string>twint-issuer5</string>
    <string>twint-issuer6</string>
    <string>twint-issuer7</string>
    <string>twint-issuer8</string>
    <string>twint-issuer9</string>
    <string>twint-issuer10</string>
    <string>twint-issuer11</string>
    <string>twint-issuer12</string>
    <string>twint-issuer13</string>
    <string>twint-issuer14</string>
    <string>twint-issuer15</string>
    <string>twint-issuer16</string>
    <string>twint-issuer17</string>
    <string>twint-issuer18</string>
    <string>twint-issuer19</string>
    <string>twint-issuer20</string>
    <string>twint-issuer21</string>
    <string>twint-issuer22</string>
    <string>twint-issuer23</string>
    <string>twint-issuer24</string>
    <string>twint-issuer25</string>
    <string>twint-issuer26</string>
    <string>twint-issuer27</string>
    <string>twint-issuer28</string>
    <string>twint-issuer30</string>
    <string>twint-issuer31</string>
    <string>twint-issuer32</string>
    <string>twint-issuer33</string>
    <string>twint-issuer34</string>
    <string>twint-issuer35</string>
    <string>twint-issuer36</string>
    <string>twint-issuer37</string>
    <string>twint-issuer38</string>
    <string>twint-issuer39</string>
    <string>twint-extended</string>
 </array>



```

## Verify payment

As customers could quit the app or lose network connection before the result is handled or malicious clients could manipulate the response, it is strongly recommended to set up your server to listen for webhook events the get transactions' actual states. Find more information in the [webhook documentation](https://checkout.postfinance.ch/en-us/doc/webhooks).
