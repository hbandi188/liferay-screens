/**
* Copyright (c) 2000-present Liferay, Inc. All rights reserved.
*
* This library is free software; you can redistribute it and/or modify it under
* the terms of the GNU Lesser General Public License as published by the Free
* Software Foundation; either version 2.1 of the License, or (at your option)
* any later version.
*
* This library is distributed in the hope that it will be useful, but WITHOUT
* ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
* FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more
* details.
*/
import UIKit


public func nullIfEmpty(string: String?) -> String? {
	if string == nil {
		return nil
	}
	else if string! == "" {
		return nil
	}

	return string
}

public func synchronized(lock: AnyObject, closure: () -> Void) {
	objc_sync_enter(lock)
	closure()
	objc_sync_exit(lock)
}


public func dispatch_delayed(delay: TimeInterval, block: @escaping () -> Void) {
    DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: block)
}

public func dispatch_async(block: () -> Void) {
    let queue = DispatchQueue.global(priority: .background)
    queue.async() {
		block()
	}
}


public func dispatch_async(block: () -> Void, thenMain mainBlock: () -> Void) {
    let queue = DispatchQueue.global(priority: .background)

    queue.async() {
		block()

        DispatchQueue.main.async {
            mainBlock()
        }
	}
}


public typealias Signal = () -> ()

public func dispatch_sync(block: (Signal) -> ()) {
    let waitGroup = DispatchGroup()
    waitGroup.enter()
	block {
        waitGroup.leave()
	}
    waitGroup.wait(timeout: .distantFuture)
}

public func to_sync(function: (Signal) -> ()) -> () -> () {
	return {
        dispatch_sync(block: function)
	}
}

public func dispatch_main(block: () -> Void) {
    if Thread.isMainThread {
		block()
	}
	else {
        DispatchQueue.main.async {
            block()
        }
	}
}

public func dispatch_main(forceDispatch: Bool, block: () -> Void) {
    if !forceDispatch && Thread.isMainThread {
		block()
	}
	else {
        DispatchQueue.main.async {
            block()
        }
	}
}



public func ScreenletName(klass: AnyClass) -> String {
	var className = NSStringFromClass(klass)

    if className.firstIndex(of: ".") != nil {
        className = String(className.split(separator: ".")[1])
    }
    
    return className.components(separatedBy: "Screenlet")[0]
}

public func LocalizedString(tableName: String, key: String, obj: AnyObject) -> String {
	let fullKey = "\(tableName)-\(key)"

    func getString(bundle: Bundle) -> String? {
		let res = NSLocalizedString(fullKey,
			tableName: tableName,
			bundle: bundle,
			value: fullKey,
			comment: "");

		return (res.lowercased() != fullKey.lowercased()) ? res : nil
	}

    let bundles = Bundle.allBundles(currentClass: type(of: obj))

	for bundle in bundles {
		// use forced language bundle
        if let languageBundle = NSLocale.bundleForCurrentLanguageInBundle(bundle: bundle) {
            if let res = getString(bundle: languageBundle) {
				return res
			}
		}

		// try with outer bundle
        if let res = getString(bundle: bundle) {
			return res
		}
	}

	return key
}


public func isOSAtLeastVersion(version: String) -> Bool {
    let currentVersion = UIDevice.current.systemVersion
	if currentVersion.compare(version,
                              options: .numeric,
                              range: nil,
                              locale: nil) != ComparisonResult.orderedAscending {

		return true
	}

	return false
}


public func isOSEarlierThanVersion(version: String) -> Bool {
    return !isOSAtLeastVersion(version: version)
}


public func adjustRectForCurrentOrientation(rect: CGRect) -> CGRect {
	var adjustedRect = rect

    if isOSEarlierThanVersion(version: "8.0") {
		// For 7.x and earlier, the width and height are reversed when
		// the device is landscaped
		switch UIDevice.current.orientation {
        case .landscapeLeft, .landscapeRight:
				adjustedRect = CGRect(
                    x: rect.origin.y, y: rect.origin.x,
                    width: rect.size.height, height: rect.size.width)
			default: ()
		}
	}

	return adjustedRect
}

public func centeredRectInView(view: UIView, size: CGSize) -> CGRect {
	return CGRect(
        x: (view.frame.size.width - size.width) / 2,
        y: (view.frame.size.height - size.height) / 2,
        width: size.width,
        height: size.height)
}
