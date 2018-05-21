//
//  LPMainViewController.swift
//  LPLoggerDemo
//
//  Created by pengli on 2018/5/21.
//  Copyright © 2018年 pengli. All rights reserved.
//

import UIKit
import LPLogger

class LPMainViewController: UITableViewController {
    let ds: [(id: LPLogger.Level, title: String)] = {
        return [(.verbose, "verbose"),
                (.debug, "debug"),
                (.info, "info"),
                (.warning, "warning"),
                (.error, "error"),
                (.severe, "severe")]
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ds.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LPMainCell",
                                                 for: indexPath)
        cell.textLabel?.text = ds[indexPath.row].title
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let model = ds[indexPath.row]
        switch model.id {
        case .verbose:
            log.verbose(model.title)
        case .debug:
            log.debug(model.title)
        case .info:
            log.info(model.title)
        case .warning:
            log.warning(model.title)
        case .error:
            log.error(model.title)
        case .severe:
            log.severe(model.title)
        case .none:
            print("none")
        }
    }
}
