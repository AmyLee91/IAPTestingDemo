#  IAPHelper

Implementing and testing In-App Purchases in Xcode 12 and iOS 14

## Synopsis
In this document we will review:

* **[Basic Steps](#Basic-Steps)**: An overview of what it takes to support in-app purchases in an iOS app
* **[Basic Example](#Basic-Example)**: A basic example of how to handle in-app purchases
* **[Xcode 12 Improvements](#Xcode-12-Improvements)**: In-app purchase-related improvements in Xcode 12 and iOS 14
* **[Receipt Validation Approaches](#Receipt-Validation-Approaches)**: Approaches to validating and reading the App Store receipt
* **[IAPHelper Framework](#IAPHelper-Framework)**: An example of how to wrap-up in-app purchase related code in a framework

## Basic Steps
The code we write to manage in-app purchases is critically important to the success of our apps. However, let's say it out loud: 
if you've not tackled it before, implementing and testing in-app purchases is daunting, complex and seems *way* more involved than 
you'd expect!   

Anybody wanting to support in-app purchases faces a similar set of challenges:

* How do you define a set of products your app supports?
* Working with StoreKit to request localized product data and initiate purchases (and restoring purchases) 
* Implementing StoreKit delegate methods to process async notifications of purchase success, failure, etc.
* Handling edge-cases, like when a purchase is deferred because it requires parental permissions, or when entitlements for a user have changed and access to the specified IAPs has been revoked
* Should you handle App Store receipt validation on-device or server-side?
* Should you write your own receipt validation code or use a service like RevenueCat?
* Working with OpenSSL and the arcane ASN.1 data structures found in receipts
* Writing code to validate the receipt and read in-app purchase data
* Defining in-app purchases in App Store Connect
* Creating and managing sandbox accounts used for testing

When I first implemented in-app purchases in one of my apps in 2016 the two main pain-points were:

### Receipt validation
The App Store issues an encrypted receipt when in-app purchases are made. This receipt contains a complete list of all in-app 
purchases made in the app. However, reading and validating the contents of the receipt can be done on-device or server-side. 
Which method should you choose?

**Server-side validation** is easier, *but* you need an app server to send requests to the App Store server. Apple specifically says 
you **should not** create direct connections to the App Store server from your app because you can't guard against 
man-in-the-middle attacks. Despite this clear warning, the web has many examples (including commercial offerings) of using 
direct app-to-App Store connections. The advantage of using server-side validation is that you can retrieve easily decoded
JSON payloads that include all the in-app purchase data you need.

**On-device validation** (no network connection required) is tricky and requires use the C-based [OpenSSL](https://www.openssl.org) library 
to decrypt and read the data. Note that including the required two OpenSSL libraries adds nearly 50MB to your app. 

Back in 2016 I fully expected StoreKit or some other Apple framework to provide ready-to-use abstractions allowing for easy access 
to the low-level cryptographic data structures in the receipt. However, as I looked deeper into this "where's the receipt processing framework?"
conundrum the more the answer became clear: having a ready-to-use framework creates a security risk because "hackers" wishing to access your
in-app purchases for-free know in advance where and how to concentrate their attacks. Apple's answer was (*and still is*): create your own custom 
receipt validation solution because a unique solution will be harder to hack.

Clearly a custom solution (if done correctly!) will be more secure. But, as all developers know that have attempted it, writing security-critical 
cryptographic-related code is **hard** and if you get it wrong diasters will happen! In my opinion, surely it would be better for Apple to
provide something that enables correct and *reasonably secure* receipt validation for the general app developer? 

However, at present (August 2020) you have no choice if you want to validate and read receipt data on-device you must develop your
own OpenSSL-based solution. If you don't feel confident doing this feel free to adapt (or use as-is) the code presented in the 
[IAPHelper Framework](#IAPHelper-Framework). 
    
### Working with sandbox accounts to test in-app purchases
Prior to Xcode 12, in order to test in-app purchases you needed to create multiple sandbox test accounts in App Store Connect. 
Each sandbox account has to have a unique email address and be validated as an AppleID. In addition, tests must be on a real device, 
not the simulator. 

On the test device you need to sign out of your normal AppleID and sign-in using the sandbox account. This really means you need a 
spare device to do testing on. To make things more painful, each time you make a purchase using a sandbox account that account 
becomes "used up" and can't be used to re-purchase the same product. There's no way to clear purchases, so you need to use a fresh 
sandbox account for each set of product purchases.

## Basic Example

![](./readme-assets/iap1.jpg)

## Xcode 12 Improvements

## Receipt Validation Approaches

## IAPHelper Framework


