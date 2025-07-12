//
//  MenuViewController.swift
//  Metal Camera
//
//  Created by Nate  on 7/10/25.
//  Copyright © 2025 Old Yellow Bricks. All rights reserved.
//

//Topography Button -> leads to Patient Form
//Composite Topography Button -> leads to Patient Form

//ReCalibrate -> Calibration View

//Patient List ------------
// Existing Patient Name -> Patient Data View

// Patient Form ------------
// Existing Patient Button -> Enter/Save Patient Info -> CameraView
// Saved Patient Button -> Camera View

// Patient Data View ------------
// DATA FROM PATINET MODEL
import UIKit
import SwiftUI

class DashboardViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    private var patients: [Patient] = []

    // MARK: - UI Elements

    private let topographyButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Topography", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let compositeTopographyButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Composite", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let calibrationButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Calibration", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let addPatientButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "plus"), for: .normal)
        button.tintColor = .systemBlue
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let patientTableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "PatientCell")
        return tableView
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .systemBackground

        view.addSubview(topographyButton)
        view.addSubview(compositeTopographyButton)
        view.addSubview(calibrationButton)
        view.addSubview(addPatientButton)
        view.addSubview(patientTableView)

        patientTableView.dataSource = self
        patientTableView.delegate = self

        NSLayoutConstraint.activate([
            // Topography button
            topographyButton.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 15),
            topographyButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 70),
            topographyButton.widthAnchor.constraint(equalToConstant: 120),
            topographyButton.heightAnchor.constraint(equalToConstant: 150),

            // Composite Topography button
            compositeTopographyButton.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 140),
            compositeTopographyButton.topAnchor.constraint(equalTo: topographyButton.bottomAnchor, constant: -150),
            compositeTopographyButton.widthAnchor.constraint(equalToConstant: 120),
            compositeTopographyButton.heightAnchor.constraint(equalToConstant: 150),

            // Calibration button
            calibrationButton.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 265),
            calibrationButton.topAnchor.constraint(equalTo: topographyButton.bottomAnchor, constant: -150),
            calibrationButton.widthAnchor.constraint(equalToConstant: 120),
            calibrationButton.heightAnchor.constraint(equalToConstant: 150),

            // Add patient button
            addPatientButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: -20),
            addPatientButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            addPatientButton.widthAnchor.constraint(equalToConstant: 44),
            addPatientButton.heightAnchor.constraint(equalToConstant: 44),

            // Patient table view
            patientTableView.topAnchor.constraint(equalTo: calibrationButton.bottomAnchor, constant: 30),
            patientTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            patientTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            patientTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupActions() {
        addPatientButton.addTarget(self, action: #selector(addPatientTapped), for: .touchUpInside)
        topographyButton.addTarget(self, action: #selector(topographyTapped), for: .touchUpInside)
        compositeTopographyButton.addTarget(self, action: #selector(compositeTopographyTapped), for: .touchUpInside)
        calibrationButton.addTarget(self, action: #selector(calibrationTapped), for: .touchUpInside)
    }

    // MARK: - Button Actions

    @objc private func addPatientTapped() {
        let formVC = PatientFormViewController()
        formVC.onSavePatient = { [weak self] newPatient in
            self?.patients.append(newPatient)
            self?.patientTableView.reloadData()
        }
        let navController = UINavigationController(rootViewController: formVC)
        present(navController, animated: true)
    }

    @objc private func topographyTapped() {
        let topographyCamera = CameraViewController()
        let navController = UINavigationController(rootViewController: topographyCamera)
        present(navController, animated: true)
    }

    @objc private func compositeTopographyTapped() {
        print("Composite Topography button tapped")
    }

    @objc private func calibrationTapped() {
        print("Calibration button tapped")
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
}


// MARK: - SwiftUI Preview
struct DashboardViewController_Previews: PreviewProvider {
    static var previews: some View {
        UIViewControllerPreview {
            // Wrap in navigation controller to show the title
            UINavigationController(rootViewController: DashboardViewController())
        }
        .previewDisplayName("Dashboard")
    }
}

// Helper struct to wrap UIViewController in SwiftUI
struct UIViewControllerPreview<ViewController: UIViewController>: UIViewControllerRepresentable {
    let viewController: ViewController
    
    init(_ builder: @escaping () -> ViewController) {
        viewController = builder()
    }
    
    func makeUIViewController(context: Context) -> ViewController {
        viewController
    }
    
    func updateUIViewController(_ uiViewController: ViewController, context: Context) {
        // Update the view controller if needed
    }
}
