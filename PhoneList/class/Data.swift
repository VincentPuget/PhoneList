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
  
  let nsAppDelegate: AppDelegate = NSApplication.shared().delegate as! AppDelegate
  
  class var instance : Data
  {
    struct Static
    {
      static let instance : Data = Data()
    }
    return Static.instance
  }
  
  func getPersons(forceUpdate: Bool, completionHandler: @escaping ([Person]?, NSError?) -> Void ) -> Void {
    
    let url: String! = Const.Webservice.URL + Const.Webservice.PHONE_ENDPOINT
//    print(url)
    
    self.getOnlineData(url: url) { (json, error) -> Void in
      if(error != nil){
        if(error?.code == 3000 || error?.code == 1000 || error?.code == 2000){
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
              let personsSorted: [Person] = (persons?.sorted { $0.firstname?.localizedCaseInsensitiveCompare($1.firstname!) == ComparisonResult.orderedAscending })!
              completionHandler(personsSorted, nil)
            }
          }
        }
        else if(error?.code == 10000){
          let error = NSError(domain: "NO_NETWORK", code: 10000, userInfo: nil)
          L.v(error.domain as AnyObject!)
          completionHandler(nil, error)
        }
        else{
          L.v(error?.domain as AnyObject!)
          completionHandler(nil, error)
        }
      }
      else {
        _ = self.dropAll()
        if let persons:NSArray = json as NSArray?{
          let personsCD: [Person] = self.savePersons(persons: persons)
          let personsCDSorted: [Person] = (personsCD.sorted { $0.firstname?.localizedCaseInsensitiveCompare($1.firstname!) == ComparisonResult.orderedAscending })
          completionHandler(personsCDSorted, nil)
        }
      }
    }
    return
  }
  
  func getPersonsCoreData(completionHandler: @escaping ([Person]?, NSError?) -> Void ) -> Void {
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Person")
    if let fetchResults = (try? nsAppDelegate.managedObjectContext.fetch(fetchRequest)) as? [Person]
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
  
  func getOnlineData(url: String!, completionHandler: @escaping ([NSDictionary]?, NSError?) -> Void ) -> Void {
    
    let loginString: String = String(format: "%@:%@", Const.Webservice.identifier, Const.Webservice.password)
    let loginData = loginString.data(using: String.Encoding.utf8)!
    let base64LoginString = loginData.base64EncodedString()
    let basicBase64LoginString: String = String(format: "%@%@", "Basic ", base64LoginString)
    
    let requestURL: NSURL = NSURL(string: url)!
    let urlRequest: NSMutableURLRequest = NSMutableURLRequest(url: requestURL as URL)
    urlRequest.httpMethod = "GET";
    
    urlRequest.setValue(basicBase64LoginString, forHTTPHeaderField: "Authorization")
    let session = URLSession.shared
    let task = session.dataTask(with: urlRequest as URLRequest) {
      (data, response, error) -> Void in
      
      var statusCode: Int?
      let httpResponse: HTTPURLResponse? = response as? HTTPURLResponse
      statusCode = httpResponse?.statusCode != nil ? httpResponse?.statusCode : 10000
      let statusCodeF: Float? = Float(statusCode!)
      let firstCharStatusCode: Float = floor(statusCodeF! / 100)
      
      if (statusCode == 200) {
        do{
          if let json: [NSDictionary] = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [NSDictionary] {
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
      else if(statusCode == 10000){
        let error = NSError(domain: "ERROR_NO_NETWORK", code: 10000, userInfo: nil)
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
    let newVersion:Version! = NSEntityDescription.insertNewObject(forEntityName: "Version", into: nsAppDelegate.managedObjectContext) as! Version
    newVersion.md5 = version;
    newVersion.lastModified = NSDate();
    
    do {
      try nsAppDelegate.managedObjectContext.save()
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
      let newPerson:Person! = NSEntityDescription.insertNewObject(forEntityName: "Person", into: nsAppDelegate.managedObjectContext) as! Person
      
      var photoUrl: String = ""
      if let photoObject: NSDictionary = (personDict["photo"] as? NSDictionary) {
        photoUrl = String(format:"%@%@", Const.Webservice.URL, (photoObject["url"] as? String)!)
      }
      newPerson.photo = photoUrl
      
      newPerson.firstname = personDict["firstname"] as? String
      newPerson.lastname = personDict["lastname"] as? String
      newPerson.number = personDict["number"] as? String
      newPerson.fullname = String(format: "%@ %@", (personDict["firstname"] as? String)!, (personDict["lastname"] as? String)!)
      personsCD.append(newPerson)
      
      do {
        try nsAppDelegate.managedObjectContext.save()
        L.v("savePerson OK" as AnyObject!)
      }
      catch {
        
      }
    }
    return personsCD
  }
  
  func dropVersion() -> Bool{
    var result:Bool! = false;
    let fetchRequestVersion = NSFetchRequest<NSFetchRequestResult>(entityName: "Version")
    if let fetchResults = (try? nsAppDelegate.managedObjectContext.fetch(fetchRequestVersion)) as? [Version]
    {
      if(fetchResults.count > 0){
        for data:AnyObject in fetchResults
        {
          nsAppDelegate.managedObjectContext.delete(data as! Version)
        }
      }
    }
    do {
      try nsAppDelegate.managedObjectContext.save()
      result = true
    }
    catch {
      result = false;
    }
    
    return result;
  }
  
  func dropPersons() -> Bool{
    var result:Bool! = false;
    let fetchRequestPerson = NSFetchRequest<NSFetchRequestResult>(entityName: "Person")
    if let fetchResults = (try? nsAppDelegate.managedObjectContext.fetch(fetchRequestPerson)) as? [Person]
    {
      if(fetchResults.count > 0){
        for data:AnyObject in fetchResults
        {
          nsAppDelegate.managedObjectContext.delete(data as! Person)
        }
      }
    }
    do {
      try nsAppDelegate.managedObjectContext.save()
      result = true
    }
    catch {
      result = false;
    }
    
    return result;
  }
  
  func dropAll() -> Bool {
    var result:Bool! = false;
    
    _ = self.dropVersion()
    _ = self.dropPersons()

    do {
      try nsAppDelegate.managedObjectContext.save()
      result = true
    }
    catch {
      result = false;
    }
    
    return result;
  }
  
}
