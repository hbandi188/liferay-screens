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


public class DDLFieldDocument : DDLField {

	public enum UploadStatus: Hashable, Equatable {
		case Uploaded([String:AnyObject])
		case Failed(NSError?)
		case Uploading(UInt64, UInt64)
		case Pending

		public static func CachedStatusData(cacheKey: String) -> [String:AnyObject] {
			[
				"cached": cacheKey as AnyObject,
				"mimeType": "image/png" as AnyObject]
		}

		public var hashValue: Int {
			toInt()
		}

		private func toInt() -> Int {
			switch self {
			case .Uploaded(_):
				return 1
			case .Failed(_):
				return 2
			case .Uploading(_,_):
				return 3
			case .Pending:
				return 4
			}
		}

	}


	public var uploadStatus = UploadStatus.Pending

	public var mimeType: String? {
		if cachedKey != nil {
			switch uploadStatus {
			case .Uploaded(let json):
				return json["mimeType"] as? String
			default: ()
			}
		}

		switch currentValue {
		case is UIImage:
			return "image/png"
		case is NSURL:
			return "video/mpeg"
		case is [String:AnyObject]:
			return nil
		default:
			return nil
		}
	}

	public var cachedKey: String? {
		switch uploadStatus {
		case .Uploaded(let json):
			return json["cached"] as? String
		default: ()
		}

		return nil
	}


	//MARK: DDLField

	public override init(attributes: [String:AnyObject], locale: NSLocale) {
		super.init(attributes: attributes, locale: locale)
	}

	public required init?(coder aDecoder: NSCoder) {
        let uploadStatusHash = aDecoder.decodeInteger(forKey: "uploadStatusHash")

		switch uploadStatusHash {
		case UploadStatus.Uploaded([:]).hashValue:
            let attributes = aDecoder.decodeObject(forKey: "uploadStatusUploadedAttributes") as!  [String:AnyObject]
			uploadStatus = .Uploaded(attributes)

		case UploadStatus.Failed(nil).hashValue:
            let err = aDecoder.decodeObject(forKey: "uploadStatusFailedError") as! NSError
			uploadStatus = .Failed(err)

		case UploadStatus.Uploading(0, 0).hashValue:
            let n1 = aDecoder.decodeObject(forKey: "uploadStatusUploading1") as! NSNumber
            let n2 = aDecoder.decodeObject(forKey: "uploadStatusUploading2") as! NSNumber
            uploadStatus = .Uploading(n1.uint64Value, n2.uint64Value)

		default:
			()
		}

		super.init(coder: aDecoder)
	}

    public override func encode(with coder: NSCoder) {
        super.encode(with: coder)

        coder.encode(uploadStatus.hashValue, forKey: "uploadStatusHash")

		switch uploadStatus {
		case .Uploaded(let attributes):
            coder.encode(attributes, forKey: "uploadStatusUploadedAttributes")
		case .Failed(let error):
            coder.encode(error, forKey: "uploadStatusFailedError")
		case .Uploading(let n1, let n2):
            coder.encode(NSNumber(value: n1), forKey: "uploadStatusUploading1")
            coder.encode(NSNumber(value: n2), forKey: "uploadStatusUploading2")
		case .Pending:
			()
		}
	}


	override internal func convert(fromString value:String?) -> AnyObject? {
		var result:AnyObject?

		if let valueString = value {
            let data = valueString.data(using: String.Encoding.utf8,
				allowLossyConversion: false)

            let jsonObject: Any? = try? JSONSerialization.jsonObject(with: data!,
                                                                                   options: JSONSerialization.ReadingOptions(rawValue: 0))

			if let jsonDict = jsonObject as? [String:AnyObject] {
				uploadStatus = .Uploaded(jsonDict)
                result = jsonDict as AnyObject
			}
			else if valueString != "" {
				uploadStatus = .Pending
                result = valueString as AnyObject
			}
		}

		return result
	}

	override func convert(fromLabel label: String?) -> AnyObject? {
		nil
	}

	override internal func convert(fromCurrentValue value: AnyObject?) -> String? {
		switch uploadStatus {
		case .Uploaded(let json):
			if let groupId = json["groupId"] as? NSNumber,
			   let uuid = json["uuid"] as? String,
			   let version = json["version"] as? String {
				return "{\"groupId\":\(groupId)," +
						"\"uuid\":\"\(uuid)\"," +
						"\"version\":\"\(version)\"}"
			}
			else {
                let data = try? JSONSerialization.data(withJSONObject: json,
					options: [])

				if let data = data {
                    return NSString(data: data, encoding: String.Encoding.utf8.rawValue) as String?
				}
			}

		default: ()
		}

		return nil
	}

	override func convertToLabel(fromCurrentValue value: AnyObject?) -> String? {
		switch currentValue {
		case is UIImage:
            return LocalizedString(tableName: "core", key: "an-image-has-been-selected", obj: self)
		case is NSURL:
            return LocalizedString(tableName: "core", key: "a-video-has-been-selected", obj: self)
		case is [String:AnyObject]:
            return LocalizedString(tableName: "core", key: "a-file-is-already-uploaded", obj: self)
		default: ()
		}

		return nil
	}

	override internal func doValidate() -> Bool {
		var result = super.doValidate()

		if result {
			switch uploadStatus {
			case .Failed(_):
				result = false
			default:
				result = true
			}
		}

		return result
	}


	//MARK: Public methods

    public func getStream(size: inout Int64) -> InputStream? {
        var result: InputStream?

		switch currentValue {
		case let image as UIImage:
            if let imageData = image.pngData() {
                size = Int64(imageData.count)
                result = InputStream(data: imageData)
			}

		case let videoURL as NSURL:
            let attributes = try? FileManager.default.attributesOfItem(
                atPath: videoURL.path!)
            if let sizeValue = attributes?[FileAttributeKey.size] as? NSNumber {
                size = sizeValue.int64Value
			}
            result = InputStream(url: videoURL as URL)

		default: ()
		}

		return result
	}

}


//MARK: Equatable

public func ==(
		left: DDLFieldDocument.UploadStatus,
		right: DDLFieldDocument.UploadStatus)
		-> Bool {
	left.hashValue == right.hashValue
}
