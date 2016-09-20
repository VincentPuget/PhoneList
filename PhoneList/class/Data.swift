//
//  Data.swift
//  PhoneList
//
//  Created by Vincent PUGET on 16/09/2016.
//  Copyright © 2016 Vincent PUGET. All rights reserved.
//

import Cocoa
import CoreData
import Foundation

class Data: NSObject{
  
  class var instance : Data
  {
    struct Static
    {
      static let instance : Data = Data()
    }
    return Static.instance
  }
  
  func getPersons(completionHandler: @escaping ([Person]?, NSError?) -> Void ) -> Void {
    //get hash of web data
    getMd5CoreData(){ (version, error) -> Void in
      
      var url: String! = Const.Webservice.URL + Const.Webservice.PHONE_ENDPOINT + "?"
      
      //if version stored in coredata, we add version on url request
      if(error == nil){
        url = url + Const.Webservice.PHONE_ENDPOINT_$GET_VERSION + "="
      }
      print(url)
      //get json online
      self.getOnlineData(url: url) { (json, error) -> Void in
        if(error != nil){
          if(error?.code == 3000 || error?.code == 1000 || error?.code == 2000){
            L.v(error?.domain as AnyObject!)
            //if 3000 error ==> it mean 304 || error JSON || error network
            // get coredata data
            self.getPersonsCoreData(){ (persons, error) -> Void in
              if(error != nil){
                //if no coredata stored, delete all and restart
                if(self.dropAll() == true){
                  let error = NSError(domain: "DROP_ALL_RESTART", code: 8000, userInfo: nil)
                  L.v(error.domain as AnyObject!)
                  completionHandler(nil, error)
                }
                else{
                  let error = NSError(domain: "DROP_ALL_BUG", code: 9000, userInfo: nil)
                  L.v(error.domain as AnyObject!)
                  completionHandler(nil, error)
                }
              }
              else{
                completionHandler(persons, nil)
              }
            }
          }
          else{
            L.v(error?.domain as AnyObject!)
            completionHandler(nil, error)
          }
        }
        else {
          let personKey: String! = Const.Webservice.PERSON_KEY
          let versionKey: String! = Const.Webservice.VERSION_KEY
          
          if let versionFromUrl: String = json?[versionKey] as? String{
            _ = self.saveVersion(version: versionFromUrl)
          }
          if let persons:NSArray = json?[personKey] as? NSArray{
            let personsCD: [Person] = self.savePersons(persons: persons)
            completionHandler(personsCD, nil)
            
          }
        }
      }
      
    }
    return
  }
  
  func getMd5CoreData(completionHandler: @escaping (String?, NSError?) -> Void ) -> Void {
    var version:Version;
    
    var md5: String = "";
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Version")
    if let fetchResults = (try? self.managedObjectContext.fetch(fetchRequest)) as? [Version]
    {
      if(fetchResults.count > 0)
      {
        version = fetchResults[0] as Version
        md5 = version.md5!
        completionHandler(md5, nil)
      }
      else{
        let error = NSError(domain: "ERROR_NO_CORE_DATA_VERSION", code: 6000, userInfo: nil)
        L.v(error.domain as AnyObject!)
        completionHandler(nil, error)
      }
    }
    return
  }
  
  func getPersonsCoreData(completionHandler: @escaping ([Person]?, NSError?) -> Void ) -> Void {
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Person")
    if let fetchResults = (try? self.managedObjectContext.fetch(fetchRequest)) as? [Person]
    {
      if(fetchResults.count > 0)
      {
        let persons = fetchResults as [Person];
        completionHandler(persons, nil)
      }
      else{
        let error = NSError(domain: "ERROR_NO_CORE_DATA_PERSONS", code: 6000, userInfo: nil)
        L.v(error.domain as AnyObject!)
        completionHandler(nil, error)
      }
    }
    return
  }
  
  func getOnlineData(url: String!, completionHandler: @escaping (AnyObject?, NSError?) -> Void ) -> Void {
    let requestURL: NSURL = NSURL(string: url)!
    let urlRequest: NSMutableURLRequest = NSMutableURLRequest(url: requestURL as URL)
    let session = URLSession.shared
    let task = session.dataTask(with: urlRequest as URLRequest) {
      (data, response, error) -> Void in
      
      let httpResponse: HTTPURLResponse! = response as! HTTPURLResponse
      let statusCode: Int! = httpResponse.statusCode
      let statusCodeF: Float! = Float(statusCode)
      let firstCharStatusCode: Float = floor(statusCodeF / 100)
      
      if (statusCode == 200) {
        do{
          if let json:NSDictionary = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? NSDictionary {
            completionHandler(json, nil)
          }
          else{
            let error = NSError(domain: "ERROR_JSON", code: 1000, userInfo: nil)
            L.v(error.domain as AnyObject!)
            completionHandler(nil, error)
            return
          }
        }
        catch {
          let error = NSError(domain: "ERROR_JSON", code: 1000, userInfo: nil)
          L.v(error.domain as AnyObject!)
          completionHandler(nil, error)
        }
      }
      else if(statusCode == 304){
        let error = NSError(domain: "ERROR_304_NOT_MODIFIED", code: 3000, userInfo: nil)
        L.v(error.domain as AnyObject!)
        completionHandler(nil, error)
      }
      else if(firstCharStatusCode == 4 || firstCharStatusCode == 5){
        let error = NSError(domain: "ERROR_NETWORK", code: 2000, userInfo: nil)
        L.v(error.domain as AnyObject!)
        completionHandler(nil, error)
      }
    }
    
    task.resume()
    return;
  }
  
  func saveVersion(version: String!) -> Bool{
    let newVersion:Version! = NSEntityDescription.insertNewObject(forEntityName: "Version", into: self.managedObjectContext) as! Version
    newVersion.md5 = version;
    newVersion.lastModified = NSDate();
    do {
      try self.managedObjectContext.save()
      L.v("saveVersion OK" as AnyObject!)
      return true
    }
    catch {
      return false;
    }
  }
  
  func savePersons(persons: NSArray!) -> [Person]{
    var personsCD: [Person] = []
    for person in persons{
      let personDict: NSDictionary = person as! NSDictionary
      
      let newPerson:Person! = NSEntityDescription.insertNewObject(forEntityName: "Person", into: self.managedObjectContext) as! Person
      newPerson.photo = personDict["photo"] as? String
      newPerson.firstname = personDict["firstname"] as? String
      newPerson.lastname = personDict["lastname"] as? String
      newPerson.number = personDict["number"] as? String
      personsCD.append(newPerson)
      
      do {
        try self.managedObjectContext.save()
        L.v("savePerson OK" as AnyObject!)
      }
      catch {
        
      }
    }
    return personsCD
  }
  
  func dropAll() -> Bool {
    var result:Bool! = false;
    
    let fetchRequestVersion = NSFetchRequest<NSFetchRequestResult>(entityName: "Version")
    if let fetchResults = (try? self.managedObjectContext.fetch(fetchRequestVersion)) as? [Version]
    {
      if(fetchResults.count > 0){
        for data:AnyObject in fetchResults
        {
          self.managedObjectContext.delete(data as! Person)
        }
      }
    }
    
    let fetchRequestPerson = NSFetchRequest<NSFetchRequestResult>(entityName: "Person")
    if let fetchResults = (try? self.managedObjectContext.fetch(fetchRequestPerson)) as? [Person]
    {
      if(fetchResults.count > 0){
        for data:AnyObject in fetchResults
        {
          self.managedObjectContext.delete(data as! Person)
        }
      }
    }

    do {
      try self.managedObjectContext.save()
      result = true
    }
    catch {
      result = false;
    }
    
    return result;
  }
  
  
  // MARK: - Core Data stack
  
  lazy var applicationDocumentsDirectory: Foundation.URL = {
    // The directory the application uses to store the Core Data store file. This code uses a directory named "com.apple.toolsQA.CocoaApp_CD" in the user's Application Support directory.
    let urls = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
    let appSupportURL = urls[urls.count - 1]
    return appSupportURL.appendingPathComponent("com.apple.toolsQA.CocoaApp_CD")
  }()
  
  lazy var managedObjectModel: NSManagedObjectModel = {
    // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
    let modelURL = Bundle.main.url(forResource: "PhoneList", withExtension: "momd")!
    return NSManagedObjectModel(contentsOf: modelURL)!
  }()
  
  lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
    // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. (The directory for the store is created, if necessary.) This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
    let fileManager = FileManager.default
    var failError: NSError? = nil
    var shouldFail = false
    var failureReason = "There was an error creating or loading the application's saved data."
    
    // Make sure the application files directory is there
    do {
      let properties = try self.applicationDocumentsDirectory.resourceValues(forKeys: [URLResourceKey.isDirectoryKey])
      if !properties.isDirectory! {
        failureReason = "Expected a folder to store application data, found a file \(self.applicationDocumentsDirectory.path)."
        shouldFail = true
      }
    } catch  {
      let nserror = error as NSError
      if nserror.code == NSFileReadNoSuchFileError {
        do {
          try fileManager.createDirectory(atPath: self.applicationDocumentsDirectory.path, withIntermediateDirectories: true, attributes: nil)
        } catch {
          failError = nserror
        }
      } else {
        failError = nserror
      }
    }
    
    // Create the coordinator and store
    var coordinator: NSPersistentStoreCoordinator? = nil
    if failError == nil {
      coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
      let url = self.applicationDocumentsDirectory.appendingPathComponent("PhoneList.storedata")
      do {
        try coordinator!.addPersistentStore(ofType: NSXMLStoreType, configurationName: nil, at: url, options: nil)
      } catch {
        // Replace this implementation with code to handle the error appropriately.
        
        /*
         Typical reasons for an error here include:
         * The persistent store is not accessible, due to permissions or data protection when the device is locked.
         * The device is out of space.
         * The store could not be migrated to the current model version.
         Check the error message to determine what the actual problem was.
         */
        failError = error as NSError
      }
    }
    
    if shouldFail || (failError != nil) {
      // Report any error we got.
      if let error = failError {
        NSApplication.shared().presentError(error)
        fatalError("Unresolved error: \(error), \(error.userInfo)")
      }
      fatalError("Unsresolved error: \(failureReason)")
    } else {
      return coordinator!
    }
  }()
  
  lazy var managedObjectContext: NSManagedObjectContext = {
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
    let coordinator = self.persistentStoreCoordinator
    var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
    managedObjectContext.persistentStoreCoordinator = coordinator
    return managedObjectContext
  }()
  
  // MARK: - Core Data Saving and Undo support
  
  @IBAction func saveAction(_ sender: AnyObject?) {
    // Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
    if !managedObjectContext.commitEditing() {
      NSLog("\(NSStringFromClass(type(of: self))) unable to commit editing before saving")
    }
    if managedObjectContext.hasChanges {
      do {
        try managedObjectContext.save()
      } catch {
        let nserror = error as NSError
        NSApplication.shared().presentError(nserror)
      }
    }
  }
  
  func windowWillReturnUndoManager(window: NSWindow) -> UndoManager? {
    // Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
    return managedObjectContext.undoManager
  }
  
  func applicationShouldTerminate(_ sender: NSApplication) -> NSApplicationTerminateReply {
    // Save changes in the application's managed object context before the application terminates.
    
    if !managedObjectContext.commitEditing() {
      NSLog("\(NSStringFromClass(type(of: self))) unable to commit editing to terminate")
      return .terminateCancel
    }
    
    if !managedObjectContext.hasChanges {
      return .terminateNow
    }
    
    do {
      try managedObjectContext.save()
    } catch {
      let nserror = error as NSError
      // Customize this code block to include application-specific recovery steps.
      let result = sender.presentError(nserror)
      if (result) {
        return .terminateCancel
      }
      
      let question = NSLocalizedString("Could not save changes while quitting. Quit anyway?", comment: "Quit without saves error question message")
      let info = NSLocalizedString("Quitting now will lose any changes you have made since the last successful save", comment: "Quit without saves error question info");
      let quitButton = NSLocalizedString("Quit anyway", comment: "Quit anyway button title")
      let cancelButton = NSLocalizedString("Cancel", comment: "Cancel button title")
      let alert = NSAlert()
      alert.messageText = question
      alert.informativeText = info
      alert.addButton(withTitle: quitButton)
      alert.addButton(withTitle: cancelButton)
      
      let answer = alert.runModal()
      if answer == NSAlertSecondButtonReturn {
        return .terminateCancel
      }
    }
    // If we got here, it is time to quit.
    return .terminateNow
  }
}
