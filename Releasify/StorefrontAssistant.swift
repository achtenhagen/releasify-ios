//
//  StorefrontAssistant.swift
//  Releasify
//
//  Created by Maurice Achtenhagen on 5/15/16.
//  Copyright © 2016 Fioware Studios, LLC. All rights reserved.
//

import StoreKit

class StorefrontAssistant: NSObject {
	class func countryCode(completionHandler: ((countryCode: String?, error: NSError?) -> Void)) {
		if #available(iOS 9.3, *) {
			SKCloudServiceController.requestAuthorization { (status) in
				if status != SKCloudServiceAuthorizationStatus.Authorized {
					completionHandler(countryCode: nil, error: NSError(domain: "SKCloudServiceController", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authorized to access Apple Music.", "SKCloudServiceAuthorizationStatus": NSNumber(integer:status.rawValue)]))
					return
				}
    
				let controller = SKCloudServiceController()
				controller.requestStorefrontIdentifierWithCompletionHandler({ (identifier, error) in
					if let error = error {
						completionHandler(countryCode: nil, error: error)
						return
					}
					
					guard let identifier = identifier?.componentsSeparatedByString(",").first?.componentsSeparatedByString("-").first else {
						completionHandler(countryCode: nil, error: NSError(domain: "SKCloudServiceController", code: 404, userInfo: [NSLocalizedDescriptionKey: "No identifier returned from SKCloudServiceController"]))
						return
					}
					
					guard let url = NSBundle.mainBundle().URLForResource("StorefrontCountries", withExtension: "plist"), storefronts = NSDictionary(contentsOfURL: url) else {
						completionHandler(countryCode: nil, error: NSError(domain: "StorefrontAssistant", code: 500, userInfo: [NSLocalizedDescriptionKey: "Could not load StorefrontCountries.plist"]))
						return
					}
					
					guard let code = storefronts[identifier] as? String else {
						completionHandler(countryCode: nil, error: NSError(domain: "StorefrontAssistant", code: 500, userInfo: [NSLocalizedDescriptionKey: "Could not find a country code for \(identifier)"]))
						return
					}
					
					completionHandler(countryCode: code, error: nil)
				})
			}
		}
	}
}