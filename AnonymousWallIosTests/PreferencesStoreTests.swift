//
//  PreferencesStoreTests.swift
//  AnonymousWallIosTests
//
//  Tests for PreferencesStore actor - thread-safe persistence layer
//

import Testing
import Foundation
@testable import AnonymousWallIos

struct PreferencesStoreTests {
    
    // MARK: - String Operations Tests
    
    @Test func testSetAndGetString() async {
        // Given
        let testDefaults = UserDefaults(suiteName: "test-preferences-store")!
        let store = PreferencesStore.test(userDefaults: testDefaults)
        let key = "testStringKey"
        let value = "testValue"
        
        // When
        await store.setString(value, forKey: key)
        let retrieved = await store.getString(forKey: key)
        
        // Then
        #expect(retrieved == value)
        
        // Cleanup
        testDefaults.removePersistentDomain(forName: "test-preferences-store")
    }
    
    @Test func testGetStringReturnsNilForNonexistentKey() async {
        // Given
        let testDefaults = UserDefaults(suiteName: "test-preferences-store-2")!
        let store = PreferencesStore.test(userDefaults: testDefaults)
        
        // When
        let retrieved = await store.getString(forKey: "nonexistent")
        
        // Then
        #expect(retrieved == nil)
        
        // Cleanup
        testDefaults.removePersistentDomain(forName: "test-preferences-store-2")
    }
    
    // MARK: - Bool Operations Tests
    
    @Test func testSetAndGetBool() async {
        // Given
        let testDefaults = UserDefaults(suiteName: "test-preferences-store-3")!
        let store = PreferencesStore.test(userDefaults: testDefaults)
        let key = "testBoolKey"
        
        // When
        await store.setBool(true, forKey: key)
        let retrieved = await store.getBool(forKey: key)
        
        // Then
        #expect(retrieved == true)
        
        // Cleanup
        testDefaults.removePersistentDomain(forName: "test-preferences-store-3")
    }
    
    @Test func testGetBoolReturnsFalseForNonexistentKey() async {
        // Given
        let testDefaults = UserDefaults(suiteName: "test-preferences-store-4")!
        let store = PreferencesStore.test(userDefaults: testDefaults)
        
        // When
        let retrieved = await store.getBool(forKey: "nonexistent")
        
        // Then
        #expect(retrieved == false)
        
        // Cleanup
        testDefaults.removePersistentDomain(forName: "test-preferences-store-4")
    }
    
    // MARK: - Batch Operations Tests
    
    @Test func testSaveBatch() async {
        // Given
        let testDefaults = UserDefaults(suiteName: "test-preferences-store-5")!
        let store = PreferencesStore.test(userDefaults: testDefaults)
        
        let strings = [
            "key1": "value1",
            "key2": "value2"
        ]
        let bools = [
            "bool1": true,
            "bool2": false
        ]
        
        // When
        await store.saveBatch(strings: strings, bools: bools)
        
        let string1 = await store.getString(forKey: "key1")
        let string2 = await store.getString(forKey: "key2")
        let bool1 = await store.getBool(forKey: "bool1")
        let bool2 = await store.getBool(forKey: "bool2")
        
        // Then
        #expect(string1 == "value1")
        #expect(string2 == "value2")
        #expect(bool1 == true)
        #expect(bool2 == false)
        
        // Cleanup
        testDefaults.removePersistentDomain(forName: "test-preferences-store-5")
    }
    
    @Test func testLoadBatch() async {
        // Given
        let testDefaults = UserDefaults(suiteName: "test-preferences-store-6")!
        let store = PreferencesStore.test(userDefaults: testDefaults)
        
        // Setup test data
        await store.setString("value1", forKey: "key1")
        await store.setString("value2", forKey: "key2")
        await store.setBool(true, forKey: "bool1")
        await store.setBool(false, forKey: "bool2")
        
        // When
        let result = await store.loadBatch(
            stringKeys: ["key1", "key2", "nonexistent"],
            boolKeys: ["bool1", "bool2", "nonexistentBool"]
        )
        
        // Then
        #expect(result.strings["key1"] as? String == "value1")
        #expect(result.strings["key2"] as? String == "value2")
        #expect(result.strings["nonexistent"] as? String == nil) // Cast to String to check nil properly
        #expect(result.bools["bool1"] == true)
        #expect(result.bools["bool2"] == false)
        #expect(result.bools["nonexistentBool"] == false)
        
        // Cleanup
        testDefaults.removePersistentDomain(forName: "test-preferences-store-6")
    }
    
    // MARK: - Remove Operations Tests
    
    @Test func testRemove() async {
        // Given
        let testDefaults = UserDefaults(suiteName: "test-preferences-store-7")!
        let store = PreferencesStore.test(userDefaults: testDefaults)
        let key = "testRemoveKey"
        
        await store.setString("value", forKey: key)
        #expect(await store.getString(forKey: key) == "value")
        
        // When
        await store.remove(forKey: key)
        
        // Then
        let retrieved = await store.getString(forKey: key)
        #expect(retrieved == nil)
        
        // Cleanup
        testDefaults.removePersistentDomain(forName: "test-preferences-store-7")
    }
    
    @Test func testRemoveAll() async {
        // Given
        let testDefaults = UserDefaults(suiteName: "test-preferences-store-8")!
        let store = PreferencesStore.test(userDefaults: testDefaults)
        
        await store.setString("value1", forKey: "key1")
        await store.setString("value2", forKey: "key2")
        await store.setBool(true, forKey: "key3")
        
        // When
        await store.removeAll(forKeys: ["key1", "key2", "key3"])
        
        // Then
        let string1 = await store.getString(forKey: "key1")
        let string2 = await store.getString(forKey: "key2")
        let bool1 = await store.getBool(forKey: "key3")
        
        #expect(string1 == nil)
        #expect(string2 == nil)
        #expect(bool1 == false) // Bool returns false for nonexistent keys
        
        // Cleanup
        testDefaults.removePersistentDomain(forName: "test-preferences-store-8")
    }
    
    // MARK: - Concurrency Tests
    
    @Test func testConcurrentAccess() async {
        // Given
        let testDefaults = UserDefaults(suiteName: "test-preferences-store-9")!
        let store = PreferencesStore.test(userDefaults: testDefaults)
        
        // When - concurrent writes
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<10 {
                group.addTask {
                    await store.setString("value\(i)", forKey: "concurrentKey\(i)")
                }
            }
        }
        
        // Then - all values should be present
        for i in 0..<10 {
            let value = await store.getString(forKey: "concurrentKey\(i)")
            #expect(value == "value\(i)")
        }
        
        // Cleanup
        testDefaults.removePersistentDomain(forName: "test-preferences-store-9")
    }
    
    @Test func testConcurrentBatchOperations() async {
        // Given
        let testDefaults = UserDefaults(suiteName: "test-preferences-store-10")!
        let store = PreferencesStore.test(userDefaults: testDefaults)
        
        // When - concurrent batch saves
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<5 {
                group.addTask {
                    await store.saveBatch(
                        strings: ["batchKey\(i)": "batchValue\(i)"],
                        bools: ["batchBool\(i)": true]
                    )
                }
            }
        }
        
        // Then - all values should be present
        for i in 0..<5 {
            let stringValue = await store.getString(forKey: "batchKey\(i)")
            let boolValue = await store.getBool(forKey: "batchBool\(i)")
            #expect(stringValue == "batchValue\(i)")
            #expect(boolValue == true)
        }
        
        // Cleanup
        testDefaults.removePersistentDomain(forName: "test-preferences-store-10")
    }
}
