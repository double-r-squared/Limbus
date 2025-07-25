//
//  PatientFormViewController 2.swift
//  MetalRenderCamera
//
//  Created by Nate  on 7/24/25.
//  Copyright © 2025 Old Yellow Bricks. All rights reserved.
//


import UIKit
import SwiftData

class PatientFormViewController: UIViewController {
    // MARK: - Properties
    private let modelContext: ModelContext
    
    // MARK: - UI Elements
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let firstNameTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "First Name"
        tf.borderStyle = .roundedRect
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    private let lastNameTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Last Name"
        tf.borderStyle = .roundedRect
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    private let ageTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Age"
        tf.borderStyle = .roundedRect
        tf.keyboardType = .numberPad
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    private let emailTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Email"
        tf.borderStyle = .roundedRect
        tf.keyboardType = .emailAddress
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    private let phoneTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Phone"
        tf.borderStyle = .roundedRect
        tf.keyboardType = .phonePad
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    private let addressTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Address"
        tf.borderStyle = .roundedRect
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    private let saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Save Patient", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Cancel", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        button.backgroundColor = .systemRed
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Initialization
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
        
        setupUI()
        setupActions()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "New Patient"
        
        // Add scroll view and content view
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        // Add form elements to content view
        contentView.addSubview(firstNameTextField)
        contentView.addSubview(lastNameTextField)
        contentView.addSubview(ageTextField)
        contentView.addSubview(emailTextField)
        contentView.addSubview(phoneTextField)
        contentView.addSubview(addressTextField)
        contentView.addSubview(saveButton)
        contentView.addSubview(cancelButton)
        
        // Set constraints
        NSLayoutConstraint.activate([
            // Scroll view
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            // Content view
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Form fields
            firstNameTextField.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            firstNameTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            firstNameTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            firstNameTextField.heightAnchor.constraint(equalToConstant: 44),
            
            lastNameTextField.topAnchor.constraint(equalTo: firstNameTextField.bottomAnchor, constant: 16),
            lastNameTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            lastNameTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            lastNameTextField.heightAnchor.constraint(equalToConstant: 44),
            
            ageTextField.topAnchor.constraint(equalTo: lastNameTextField.bottomAnchor, constant: 16),
            ageTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            ageTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            ageTextField.heightAnchor.constraint(equalToConstant: 44),
            
            emailTextField.topAnchor.constraint(equalTo: ageTextField.bottomAnchor, constant: 16),
            emailTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            emailTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            emailTextField.heightAnchor.constraint(equalToConstant: 44),
            
            phoneTextField.topAnchor.constraint(equalTo: emailTextField.bottomAnchor, constant: 16),
            phoneTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            phoneTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            phoneTextField.heightAnchor.constraint(equalToConstant: 44),
            
            addressTextField.topAnchor.constraint(equalTo: phoneTextField.bottomAnchor, constant: 16),
            addressTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            addressTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            addressTextField.heightAnchor.constraint(equalToConstant: 44),
            
            saveButton.topAnchor.constraint(equalTo: addressTextField.bottomAnchor, constant: 30),
            saveButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            saveButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            saveButton.heightAnchor.constraint(equalToConstant: 50),
            
            cancelButton.topAnchor.constraint(equalTo: saveButton.bottomAnchor, constant: 12),
            cancelButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            cancelButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            cancelButton.heightAnchor.constraint(equalToConstant: 50),
            cancelButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    private func setupActions() {
        saveButton.addTarget(self, action: #selector(savePatient), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        
        // Add keyboard dismissal
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    // MARK: - Actions
    @objc private func savePatient() {
        guard let firstName = firstNameTextField.text, !firstName.isEmpty else {
            showAlert(message: "First name is required")
            return
        }
        
        let lastName = lastNameTextField.text ?? ""
        let age = Int(ageTextField.text ?? "")
        let email = emailTextField.text
        let phone = phoneTextField.text
        let address = addressTextField.text
        
        let newPatient = Patient(
            firstName: firstName,
            lastName: lastName,
            age: age,
            email: email,
            phone: phone,
            address: address,
            eyeData: nil,
            imageStore: ImageStore() // Initialize with empty ImageStore
        )
        
        // Save to SwiftData
        modelContext.insert(newPatient)
        do {
            try modelContext.save()
            print("Saved patient: \(newPatient)")
            dismiss(animated: true)
        } catch {
            showAlert(message: "Failed to save patient: \(error.localizedDescription)")
        }
    }
    
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Validation Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}