/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
A convenient extension to UIKit.UIUserNotificationSettings.
*/

#if os(iOS)

import UIKit

extension UIUserNotificationSettings {
    /// Check to see if one Settings object is a superset of another Settings object.
    func contains(settings: UIUserNotificationSettings) -> Bool {
        // our types must contain all of the other types
        if !types.contains(settings.types) {
            return false
        }
        
        let otherCategories = settings.categories ?? []
        let myCategories = categories ?? []
        
        return myCategories.isSuperset(of: otherCategories)
    }
    
    /**
        Merge two Settings objects together. `UIUserNotificationCategories` with
        the same identifier are considered equal.
    */
    func settingsByMerging(settings: UIUserNotificationSettings) -> UIUserNotificationSettings {
        let mergedTypes = types.union(settings.types)
        
        let myCategories = categories ?? []
        var existingCategoriesByIdentifier: [String: UIUserNotificationCategory] = Dictionary(sequence: myCategories, keyMapper: \.identifier)
        
        let newCategories = settings.categories ?? []
        let newCategoriesByIdentifier: [String: UIUserNotificationCategory] = Dictionary(sequence: newCategories, keyMapper: \.identifier)
        
        for (newIdentifier, newCategory) in newCategoriesByIdentifier {
            existingCategoriesByIdentifier[newIdentifier] = newCategory
        }
        
        let mergedCategories = Set(existingCategoriesByIdentifier.values)
        return UIUserNotificationSettings(types: mergedTypes, categories: mergedCategories)
    }
}

#endif
