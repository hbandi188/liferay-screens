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
import Foundation


extension Bundle {

    public class func allBundles(currentClass: AnyClass) -> [Bundle] {
		let bundles =
			[
				discoverBundles(),
				[
					bundleForDefaultTheme(),
					bundleForCore(),
                    Bundle(for: currentClass)
				],
				bundlesForApp()
			]
			.flatMap { $0 }

		return bundles.reduce([]) { ac, x in
			ac.contains(x) ? ac : ac + [x]
		}
	}

    public class func discoverBundles() -> [Bundle] {
        let allBundles = Bundle.allFrameworks 

		return allBundles.filter {
			let screensPrefix = "LiferayScreens"
			let bundleName = (($0.bundleIdentifier ?? "") as NSString).pathExtension

			return bundleName.characters.count > screensPrefix.characters.count
					&& bundleName.hasPrefix(screensPrefix)
		}
	}

    public class func bundleForDefaultTheme() -> Bundle {
        let frameworkBundle = Bundle(for: BaseScreenlet.self)

        let defaultBundlePath = frameworkBundle.path(forResource: "LiferayScreens-default",
				ofType: "bundle")!

        return Bundle(path: defaultBundlePath)!
	}

    public class func bundleForCore() -> Bundle {
        let frameworkBundle = Bundle(for: BaseScreenlet.self)

        let coreBundlePath = frameworkBundle.path(forResource: "LiferayScreens-core",
				ofType: "bundle")!

        return Bundle(path: coreBundlePath)!
	}

    public class func bundlesForApp() -> [Bundle] {

		func appFile(path: String) -> String? {
            let files = try? FileManager.default.contentsOfDirectory(atPath: path)
			return (files ?? []).filter {
					($0 as NSString).pathExtension == "app"
				}
				.first
		}

        let components = ((Bundle.main.resourcePath ?? "") as NSString).pathComponents 

		if components.last == "Overlays" {
			// running into IB
			let coreBundle = bundleForCore()

			if let range = coreBundle.resourcePath?.rangeOfString("Debug-iphonesimulator"),
                let path = coreBundle.resourcePath?.substringToIndex(range.endIndex),
                let appName = appFile(path),
                let appBundle = Bundle(path: (path as NSString).stringByAppendingPathComponent(appName)) {
                return [Bundle.mainBundle(), appBundle]
			}
		}

        return [Bundle.mainBundle]
	}


    public class func imageInBundles(name: String, currentClass: AnyClass) -> UIImage? {
		for bundle in allBundles(currentClass) {
			if let path = bundle.pathForResource(name, ofType: "png") {
				return UIImage(contentsOfFile: path)
			}
		}

		return nil
	}

}
