//
//  DashboardViewController.swift
//  Metal Camera
//
//  Created by Nate  on 7/15/25.
//  Copyright © 2025 Old Yellow Bricks. All rights reserved.
//

import UIKit

class DashboardViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private var patients: [Patient] = []
    
    @IBOutlet weak var patientTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func addPatientButtonPressed(_ sender: Any) {
        print("PRESSED PATIENT BUTTON")
        let formVC = PatientFormViewController()
            formVC.onSavePatient = { [weak self] newPatient in
                self?.patients.append(newPatient)
                self?.patientTableView.reloadData()
            }
            let navController = UINavigationController(rootViewController: formVC)
            present(navController, animated: true)
        }
    
    @IBAction func topographyButtonPressed(_ sender: Any) {
        print("PRESSED TOPOGRAPHY BUTTON")
        let pickerVC = PatientPickerViewController()
        pickerVC.patients = self.patients
        pickerVC.onPatientSelected = { [weak self] patient in
            let topoVC = CameraViewController()
            topoVC.patient = patient // This passes the selected patient to the camera view
            self?.navigationController?.pushViewController(topoVC, animated: true)
        }
        present(pickerVC, animated: true)
    }
    
    @IBAction func calibrationButtonPressed(_ sender: Any) {
        print("PRESSED CALIBRATION BUTTON")
    }
    
    @IBAction func CompositeButtonPressed(_ sender: Any) {
        print("PRESSED COMPOSITE BUTTON")
    }
    
    // MARK: - Table View Data Source

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return patients.count
        }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let patient = patients[indexPath.row]
            let cell = tableView.dequeueReusableCell(withIdentifier: "PatientCell", for: indexPath)
            cell.textLabel?.text = "\(patient.firstName) \(patient.lastName)"
            return cell
        }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}


