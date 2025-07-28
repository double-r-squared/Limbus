import UIKit
import SwiftData
import SwiftUI

class DashboardViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    private let modelContext: ModelContext
    private var patients: [Patient] = []
    private var filteredPatients: [Patient] = []
    
    private let buttonStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let searchBar: UISearchBar = {
        let sb = UISearchBar()
        sb.placeholder = "Search for a patient"
        sb.translatesAutoresizingMaskIntoConstraints = false
        return sb
    }()
    
    private let tableView: UITableView = {
        let table = UITableView()
        table.translatesAutoresizingMaskIntoConstraints = false
        return table
    }()
    
    private let topographyButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Topography", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        button.backgroundColor = .systemPurple
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let compositeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Composite", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        button.backgroundColor = .systemIndigo
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let calibrationButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Calibration", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Limbus"
        view.backgroundColor = .systemBackground
        setupUI()
        fetchPatients()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchPatients() // Refresh data when returning to dashboard
    }
    
    private func setupUI() {
        view.addSubview(buttonStackView)
        view.addSubview(searchBar)
        view.addSubview(tableView)
        
        buttonStackView.addArrangedSubview(topographyButton)
        buttonStackView.addArrangedSubview(compositeButton)
        buttonStackView.addArrangedSubview(calibrationButton)
        
        searchBar.delegate = self
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "PatientCell")
        
        topographyButton.addTarget(self, action: #selector(topographyTapped), for: .touchUpInside)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "person.fill.badge.plus"),
                                                            style: UIBarButtonItem.Style.plain,
                                                            target: self, action: #selector(addNewPatientTapped))
        NSLayoutConstraint.activate([
            buttonStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            buttonStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            buttonStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            buttonStackView.heightAnchor.constraint(equalToConstant: 150),
            
            searchBar.topAnchor.constraint(equalTo: buttonStackView.bottomAnchor, constant: 10),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 10),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            filteredPatients = patients
        } else {
            filteredPatients = patients.filter {
                $0.firstName.lowercased().contains(searchText.lowercased()) ||
                $0.lastName.lowercased().contains(searchText.lowercased())
            }
        }
        tableView.reloadData()
    }
    
    private func fetchPatients() {
        do {
            let descriptor = FetchDescriptor<Patient>(sortBy: [SortDescriptor(\.lastName)])
            patients = try modelContext.fetch(descriptor)
            filteredPatients = patients
            tableView.reloadData()
        } catch {
            print("Failed to fetch patients: \(error)")
        }
    }
    
    @objc private func addNewPatientTapped() {
        let formVC = PatientFormViewController(modelContext: modelContext)
        formVC.onPatientSaved = { [weak self] in
            self?.fetchPatients()
        }
        present(formVC, animated: true)
    }
    
    @objc private func topographyTapped() {
        let pickerVC = PatientPickerViewController(modelContext: modelContext)
        pickerVC.onPatientSelected = { [weak self] patient, eyeType in
            guard let self = self else { return }
            let cameraVC = CameraViewController(modelContext: self.modelContext)
            cameraVC.patient = patient
            cameraVC.eyeType = eyeType
            let nav = UINavigationController(rootViewController: cameraVC)
            nav.modalPresentationStyle = .fullScreen
            self.present(nav, animated: true)
        }
        present(pickerVC, animated: true)
    }
    
    // MARK: UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredPatients.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PatientCell", for: indexPath)
        let patient = filteredPatients[indexPath.row]
        cell.textLabel?.text = "\(patient.firstName) \(patient.lastName)"
        
        if let eyeData = patient.eyeData {
            var detailText = ""
            if eyeData.leftEyeTimestamp != nil {
                detailText += "Left Eye: ✓"
            }
            if eyeData.rightEyeTimestamp != nil {
                if !detailText.isEmpty { detailText += ", " }
                detailText += "Right Eye: ✓"
            }
            cell.detailTextLabel?.text = detailText.isEmpty ? "No eye data" : detailText
        } else {
            cell.detailTextLabel?.text = "No eye data"
        }
        
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    // MARK: UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let patient = filteredPatients[indexPath.row]
        
        let patientInfoView = PatientInfoView(patient: patient, modelContext: modelContext)
        let hostingController = UIHostingController(rootView: patientInfoView)
        hostingController.title = "\(patient.firstName) \(patient.lastName)"
        
        navigationController?.pushViewController(hostingController, animated: true)
    }
    
    // MARK: Swipe to Delete
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let patient = filteredPatients[indexPath.row]
            
            let alert = UIAlertController(title: "Delete Patient",
                                        message: "Are you sure you want to delete \(patient.firstName) \(patient.lastName)? This action cannot be undone.",
                                        preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
                self?.deletePatient(patient, at: indexPath)
            })
            
            present(alert, animated: true)
        }
    }
    
    private func deletePatient(_ patient: Patient, at indexPath: IndexPath) {
        do {
            modelContext.delete(patient)
            try modelContext.save()
            
            // Remove from both arrays
            if let originalIndex = patients.firstIndex(where: { $0 === patient }) {
                patients.remove(at: originalIndex)
            }
            filteredPatients.remove(at: indexPath.row)
            
            tableView.deleteRows(at: [indexPath], with: .fade)
        } catch {
            print("Failed to delete patient: \(error)")
            let errorAlert = UIAlertController(title: "Error",
                                             message: "Failed to delete patient. Please try again.",
                                             preferredStyle: .alert)
            errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
            present(errorAlert, animated: true)
        }
    }
}
