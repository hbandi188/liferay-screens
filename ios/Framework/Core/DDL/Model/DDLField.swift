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


public class DDLField: NSObject, NSCoding {
    

	public var onPostValidation: ((Bool) -> Void)?
	public var lastValidationResult: Bool?

	public var currentValue: AnyObject? {
		didSet {
			onChangedCurrentValue()
		}
	}

	public var currentValueAsString:String? {
		get {
			return convert(fromCurrentValue: currentValue)
		}
		set {
			currentValue = convert(fromString: newValue)
		}
	}

	public var currentValueAsLabel: String? {
		get {
			return convertToLabel(fromCurrentValue: currentValue)
		}
		set {
			currentValue = convert(fromLabel: newValue)
		}
	}

	public override var description: String {
		let currentValue = self.currentValueAsString
		var str = "DDLField[" +
				" name=\( self.name )" +
				" type=\( self.dataType.rawValue )" +
				" editor=\( self.editorType.rawValue )"
		if currentValue != nil {
			if currentValue! == "" {
				str += " value='' ]"
			}
			else {
				str += " value=\( currentValue! ) ]"
			}
		}
		else {
			str += " ]"
		}

		return str
	}

	public var currentLocale: NSLocale


    var dataType: DataType
    var editorType: Editor

    var name: String
    var label: String
    var tip: String

    var predefinedValue: AnyObject?

    var readOnly: Bool
    var repeatable: Bool
    var required: Bool
    var showLabel: Bool


	public init(attributes: [String:AnyObject], locale: NSLocale) {
        dataType = DataType(rawValue: valueAsString(dict: attributes, key:"dataType")) ?? .Unsupported
		editorType = Editor.from(attributes: attributes)

        name = valueAsString(dict: attributes, key:"name")
        label = valueAsString(dict: attributes, key:"label")
        tip = valueAsString(dict: attributes, key:"tip")

		readOnly = Bool.from(any: attributes["readOnly"] ?? "false" as AnyObject)
		repeatable = Bool.from(any: attributes["repeatable"] ?? "false" as AnyObject)
		required = Bool.from(any: attributes["required"] ?? "true" as AnyObject)
		showLabel = Bool.from(any: attributes["showLabel"] ?? "false" as AnyObject)

		currentLocale = locale

		super.init()

		predefinedValue = attributes["predefinedValue"] ?? nil
		if predefinedValue is String {
			predefinedValue = convert(fromString: predefinedValue as? String)
		}
		else {
			let predefinedStringValue = convert(fromCurrentValue: predefinedValue)
			predefinedValue = convert(fromString: predefinedStringValue)
		}

		currentValue = predefinedValue
	}

	public required init?(coder aDecoder: NSCoder) {
        let dataTypeValue = aDecoder.decodeObject(forKey: "dataType") as? String
		dataType = DataType(rawValue: dataTypeValue ?? "") ?? .Unsupported

        let editorTypeValue = aDecoder.decodeObject(forKey: "editorType") as? String
		editorType = Editor(rawValue: editorTypeValue ?? "") ?? .Unsupported

        name = aDecoder.decodeObject(forKey: "name") as! String
        label = aDecoder.decodeObject(forKey: "label") as! String
        tip = aDecoder.decodeObject(forKey: "tip") as! String

        readOnly = aDecoder.decodeBool(forKey: "readOnly")
        repeatable = aDecoder.decodeBool(forKey: "repeatable")
        required = aDecoder.decodeBool(forKey: "required")
        showLabel = aDecoder.decodeBool(forKey: "showLabel")

        currentLocale = aDecoder.decodeObject(forKey: "currentLocale") as! NSLocale

		super.init()

        let predefinedValueString = aDecoder.decodeObject(forKey: "predefinedValue") as? String
		predefinedValue = convert(fromString: predefinedValueString)

        let currentValueString = aDecoder.decodeObject(forKey: "currentValue") as? String
		currentValue = convert(fromString: currentValueString)
	}

    public func encode(with coder: NSCoder) {
        coder.encode(currentLocale, forKey:"currentLocale")
        coder.encode(dataType.rawValue, forKey:"dataType")
        coder.encode(editorType.rawValue, forKey:"editorType")
        coder.encode(name, forKey:"name")
        coder.encode(label, forKey:"label")
        coder.encode(tip, forKey:"tip")
        coder.encode(readOnly, forKey:"readOnly")
        coder.encode(repeatable, forKey:"repeatable")
        coder.encode(required, forKey:"required")
        coder.encode(showLabel, forKey:"showLabel")
        coder.encode(convert(fromCurrentValue: currentValue), forKey:"currentValue")
        coder.encode(convert(fromCurrentValue: predefinedValue), forKey:"predefinedValue")
	}

	public func validate() -> Bool {
		var valid = !(currentValue == nil && required)

		if valid {
			valid = doValidate()
		}

		onPostValidation?(valid)

		lastValidationResult = valid

		return valid
	}

	//MARK: Internal methods

	internal func doValidate() -> Bool {
		return true
	}

	internal func convert(fromString value:String?) -> AnyObject? {
        return value as AnyObject?
	}

	internal func convert(fromLabel value:String?) -> AnyObject? {
        return value as AnyObject?
	}

	internal func convert(fromCurrentValue value:AnyObject?) -> String? {
		return value?.description
	}

	internal func convertToLabel(fromCurrentValue value:AnyObject?) -> String? {
		return value?.description
	}

	internal func onChangedCurrentValue() {
	}

}


//MARK: Equatable

public func ==(left: DDLField, right: DDLField) -> Bool {
	return left.name == right.name
}


//MARK: Util func

private func valueAsString(dict: [String:AnyObject], key: String) -> String {
	return (dict[key] ?? "" as AnyObject) as! String
}
