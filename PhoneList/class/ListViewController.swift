//
//  ListViewController.swift
//  PhoneList
//
//  Created by Vincent PUGET on 16/09/2016.
//  Copyright © 2016 Vincent PUGET. All rights reserved.
//

import Cocoa

class ListViewController: NSViewController {
  
  @IBOutlet weak var tableView: NSTableView!
  @IBOutlet weak var searchField: NSSearchField!
  @IBOutlet weak var scrollView: NSScrollView!
  
  var json:AnyObject!;
  
  var personsAC:NSArrayController = NSArrayController()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
//    Data.instance.dropAll()
    
    self.scrollView.wantsLayer = true
    self.scrollView.layer?.cornerRadius = 10
    
    self.getData()
  }
  
  override var representedObject: Any? {
    didSet {
      // Update the view, if already loaded.
    }
  }
  
  func getData(){
    Data.instance.getPersons(){ (persons, error) -> Void in
      if(error != nil) {
        if(error?.code == 8000){
          self.getData()
        }
      }
      else{
        self.personsAC.content = persons
        DispatchQueue.main.async {
          self.tableView.reloadData()
        }
      }
    }
  }
}


extension ListViewController:NSTableViewDelegate , NSTableViewDataSource
{
  //NSTableViewDelegate
  func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat{
    return 60
  }
  
  //NSTableViewDataSource
  func numberOfRows(in tableView: NSTableView) -> Int{
    return (self.personsAC.arrangedObjects as AnyObject).count;
  }
  
  func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
    let customRow = CustomRowView()
    return customRow
  }
  
//  func tableView(_ tableView: NSTableView, didAdd rowView: NSTableRowView, forRow row: Int) {
//    if(row % 2 == 1) {
//      rowView.backgroundColor = NSColor.init(red: 164/255, green: 57/255, blue: 75/255, alpha: 1)
//    }
//  }
  
  func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
    let cellView: NSTableCellView = tableView.make(withIdentifier: tableColumn!.identifier, owner: self) as! NSTableCellView
    
    let person: Person = (self.personsAC.arrangedObjects as! [Person])[row]
    
    
    if(tableColumn!.identifier == "photo")
    {
      cellView.frame = CGRect(x: 0, y: 0, width: 60, height: 60)
      cellView.imageView?.frame = CGRect(x: 0, y: 0, width: 60, height: 60)
      cellView.imageView?.image = NSImage(named:"profil.png")
      tableColumn?.headerCell.title = "Photo"
    }
    else if(tableColumn!.identifier == "firstname")
    {
      cellView.textField!.stringValue = person.firstname!
      tableColumn?.headerCell.title = "Prénom"
    }
    else if(tableColumn!.identifier == "lastname")
    {
      cellView.textField!.stringValue = person.lastname!
      tableColumn?.headerCell.title = "Nom"
    }
    else if(tableColumn!.identifier == "number")
    {
      cellView.textField!.stringValue = person.number!
      tableColumn?.headerCell.title = "Numéro"
    }
    
    return cellView
  }
}

extension ListViewController: NSSearchFieldDelegate{
  override func controlTextDidChange(_ obj: Notification){
    let searchString = ((obj.object as? NSSearchField)?.stringValue)!
    
    let predicate = NSPredicate(format: "(firstname CONTAINS[cd] %@) OR (lastname CONTAINS[cd] %@) OR (fullname CONTAINS[cd] %@)", searchString, searchString, searchString)
    
    if searchString != "" {
      self.personsAC.filterPredicate = predicate
    }
    else{
      self.personsAC.filterPredicate = nil
    }
    self.tableView.reloadData()
  }
  
}
