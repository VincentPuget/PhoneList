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
  
  func getPersons(completionHandler: @escaping ([Person]?, NSError?) -> Void ) -> Void {
    //get hash of web data
    getMd5CoreData(){ (version, error) -> Void in
      var url: String! = Const.Webservice.URL + Const.Webservice.PHONE_ENDPOINT + "?"
      //if version stored in coredata, we add version on url request
      if(error == nil){
        url = url + Const.Webservice.PHONE_ENDPOINT_$GET_VERSION + "=" + version!
      }
      print(url)
      //get json online
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
          else{
            L.v(error?.domain as AnyObject!)
            completionHandler(nil, error)
          }
        }
        else {
          _ = self.dropAll()
          let personKey: String! = Const.Webservice.PERSON_KEY
          let versionKey: String! = Const.Webservice.VERSION_KEY
          if let versionFromUrl: String = json?[versionKey] as? String{
            _ = self.saveVersion(version: versionFromUrl)
          }
          if let persons:NSArray = json?[personKey] as? NSArray{
            let personsCD: [Person] = self.savePersons(persons: persons)
            let personsCDSorted: [Person] = (personsCD.sorted { $0.firstname?.localizedCaseInsensitiveCompare($1.firstname!) == ComparisonResult.orderedAscending })
            completionHandler(personsCDSorted, nil)
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
    if let fetchResults = (try? nsAppDelegate.managedObjectContext.fetch(fetchRequest)) as? [Version]
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
  
  func getOnlineData(url: String!, completionHandler: @escaping (AnyObject?, NSError?) -> Void ) -> Void {
    let requestURL: NSURL = NSURL(string: url)!
    let urlRequest: NSMutableURLRequest = NSMutableURLRequest(url: requestURL as URL)
    urlRequest.setValue(Const.Webservice.X_JSON_MD5_VALUE, forHTTPHeaderField:Const.Webservice.X_JSON_MD5_KEY)
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
      newPerson.photo = personDict["photo"] as? String
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
