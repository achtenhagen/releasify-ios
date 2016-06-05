//
//  MD5.swift
//  Releasify
//
//  Created by Maurice Achtenhagen on 6/5/16.
//  Copyright © 2016 Fioware Studios, LLC. All rights reserved.
//

import Foundation

// MARK: - MD5 digestion extension
func md5(string: String) -> String {
	var digest = [UInt8](count: Int(CC_MD5_DIGEST_LENGTH), repeatedValue: 0)
	var digestHex = ""
	if let data = string.dataUsingEncoding(NSUTF8StringEncoding) { CC_MD5(data.bytes, CC_LONG(data.length), &digest) }
	for index in 0..<Int(CC_MD5_DIGEST_LENGTH) { digestHex += String(format: "%02x", digest[index]) }
	return digestHex
}