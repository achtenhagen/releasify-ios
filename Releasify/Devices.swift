//
//  Devices.swift
//  Releasify
//
//  Created by Maurice Achtenhagen on 5/31/15.
//  Copyright (c) 2015 Fioware Studios, LLC. All rights reserved.
//

import UIKit

public enum DeviceTypes : String {
	case simulator = "Simulator",
	iPad2          = "iPad 2",
	iPad3          = "iPad 3",
	iPad4          = "iPad 4",
	iPadMini1      = "iPad Mini 1",
	iPadMini2      = "iPad Mini 2",
	iPadMini3      = "iPad Mini 3",
	iPadAir1       = "iPad Air 1",
	iPadAir2       = "iPad Air 2",
	iPhone4        = "iPhone 4",
	iPhone4S       = "iPhone 4S",
	iPhone5        = "iPhone 5",
	iPhone5c       = "iPhone 5c",
	iPhone5S       = "iPhone 5S",
	iPhone6        = "iPhone 6",
	iPhone6plus    = "iPhone 6 Plus",
	iPhone6S       = "iPhone 6S",
	iPhone6Splus   = "iPhone 6S Plus",
	iPodTouch      = "iPod Touch",
	unrecognized   = "Unknown Device"
}

public extension UIDevice {
	public var deviceType: DeviceTypes {
		var sysinfo : [CChar] = Array(count: sizeof(utsname), repeatedValue: 0)
		let modelCode = sysinfo.withUnsafeMutableBufferPointer { (inout ptr: UnsafeMutableBufferPointer<CChar>) -> DeviceTypes in
			uname(UnsafeMutablePointer<utsname>(ptr.baseAddress))
			let machinePtr = ptr.baseAddress.advancedBy(Int(_SYS_NAMELEN * 4))
			var modelMap : [String : DeviceTypes] = [
				"iPad2,1"   : .iPad2,          // iPad (2nd Generation)
				"iPad2,2"   : .iPad2,          // iPad (2nd Generation)
				"iPad2,3"   : .iPad2,          // iPad (2nd Generation)
				"iPad2,4"   : .iPad2,          // iPad (2nd Generation)
				"iPad2,5"   : .iPadMini1,      // iPad Mini (Wifi)
				"iPad2,6"   : .iPadMini1,      // iPad Mini (GSM)
				"iPad2,7"   : .iPadMini1,      // iPad Mini (GSM + CDMA)
				"iPad3,1"   : .iPad3,          // iPad (3rd Generation)
				"iPad3,2"   : .iPad3,          // iPad (3rd Generation)
				"iPad3,3"   : .iPad3,          // iPad (3rd Generation)
				"iPad3,4"   : .iPad4,          // iPad (4th Generation)
				"iPad3,5"   : .iPad4,          // iPad (4th Generation)
				"iPad3,6"   : .iPad4,          // iPad (4th Generation)
				"iPad4,1"   : .iPadAir1,       // iPad Air (Wifi)
				"iPad4,2"   : .iPadAir1,       // iPad Air (Cellular)
				"iPad4,3"   : .iPadAir1,       // iPad Air
				"iPad4,4"   : .iPadMini2,      // iPad Mini (2nd Generation) - Wifi
				"iPad4,5"   : .iPadMini2,      // iPad Mini (2nd Generation) - Cellular
				"iPad4,6"   : .iPadMini2,      // iPad Mini (2nd Generation)
				"iPad4,7"   : .iPadMini2,      // iPad Mini (3rd Generation) - Wifi
				"iPad4,8"   : .iPadMini2,      // iPad Mini (3rd Generation) - Cellular
				"iPad4,9"   : .iPadMini2,      // iPad Mini (3rd Generation) - China
				"iPad5,3"   : .iPadAir2,       // iPad Air 2 (Wifi)
				"iPad5,4"   : .iPadAir2,       // iPad Air 2 (Cellular)
				"iPhone3,1" : .iPhone4,        // iPhone 4
				"iPhone3,2" : .iPhone4,        // iPhone 4
				"iPhone3,3" : .iPhone4,        // iPhone 4 (Verizon)
				"iPhone4,1" : .iPhone4S,       // iPhone 4S
				"iPhone5,1" : .iPhone5,        // iPhone 5 (model A1428, AT&T/Canada)
				"iPhone5,2" : .iPhone5,        // iPhone 5 (model A1429, everything else)
				"iPhone5,3" : .iPhone5c,       // iPhone 5c (model A1456, A1532 | GSM)
				"iPhone5,4" : .iPhone5c,       // iPhone 5c (model A1507, A1516, A1526 (China), A1529 | Global)
				"iPhone6,1" : .iPhone5S,       // iPhone 5S (model A1433, A1533 | GSM)
				"iPhone6,2" : .iPhone5S,       // iPhone 5S (model A1457, A1518, A1528 (China), A1530 | Global)
				"iPhone7,2" : .iPhone6,		   // iPhone 6
				"iPhone7,1" : .iPhone6plus,    // iPhone 6 Plus
				"iPhone8,1" : .iPhone6S,	   // iPhone 6S
				"iPhone8,2" : .iPhone6Splus,   // iPhone 6S Plus
				"iPod5,1"   : .iPodTouch,      // 5th Generation iPod Touch
				"iPod6,1"   : .iPodTouch,      // 6th Generation iPod Touch
				"i386"      : .simulator,
				"x86_64"    : .simulator
			]
			if let model = modelMap[String.fromCString(machinePtr)!] {
				return model
			}
			return DeviceTypes.unrecognized
		}
		return modelCode
	}
}
