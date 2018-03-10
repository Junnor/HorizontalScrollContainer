//
//  FirstViewController.swift
//  Parent
//
//  Created by Ju on 2017/12/29.
//  Copyright © 2017年 Ju. All rights reserved.
//

import UIKit

class FirstViewController: UIViewController {
    

    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.dataSource = self
            tableView.delegate = self
            tableView.rowHeight = 70
        }
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "first",
            let desvc = segue.destination as? DetailViewController,
            let indexPath = sender as? IndexPath {
            desvc.text = "Selected Row: \(indexPath.row)"
        }
    }
}

extension FirstViewController: UITableViewDataSource, UITableViewDelegate {
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 24
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = "\(indexPath.row)"
        cell.backgroundColor = UIColor.cyan.withAlphaComponent(0.6)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        performSegue(withIdentifier: "first", sender: indexPath)
    }
}
