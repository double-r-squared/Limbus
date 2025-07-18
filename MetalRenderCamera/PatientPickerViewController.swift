//
//  PatientPickerViewController.swift
//  Metal Camera
//
//  Created by Nate  on 7/15/25.
//  Copyright © 2025 Old Yellow Bricks. All rights reserved.
//

import Foundation
import UIKit

class PatientPickerViewController: UIViewController, UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate {

    var patients: [Patient] = []
    var onPatientSelected: ((Patient) -> Void)?

    private var filteredPatients: [Patient] = []

//    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
//    
//    private let dimmingView: UIView = {
//        let view = UIView()
//        view.backgroundColor = UIColor.black.withAlphaComponent(0.3)
//        return view
//    }()

    private let containerView = UIView();
    private let scrollView = UIScrollView()
    
    // MARK: Views for state
    private let optionView = UIView()
    private let searchView = UIView()
    private let formView = UIView()

    private let searchBar = UISearchBar()
    private let tableView = UITableView()
    
    // MARK: Form elements
    private let formScrollView = UIScrollView()
    private let formContentView = UIView()
    private let firstNameTextField = UITextField()
    private let lastNameTextField = UITextField()
    private let ageTextField = UITextField()
    private let emailTextField = UITextField()
    private let phoneTextField = UITextField()
    private let addressTextField = UITextField()
    private let saveAndProceedButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        modalPresentationStyle = .overFullScreen
        view.backgroundColor = .clear // Make main view transparent
        setupViews()
        setupKeyboardNotifications()
        setupTapGesture()
        
        // Initialize filtered patients to show all patients initially
        filteredPatients = patients
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeKeyboardNotifications()
    }

    private func setupViews() {
        // Container view setup
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = .systemBackground
        containerView.layer.cornerRadius = 20
        containerView.clipsToBounds = true
        containerView.layer.shadowColor = UIColor.black.cgColor // Add shadow for better visibility
        containerView.layer.shadowOpacity = 0.2
        containerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        containerView.layer.shadowRadius = 10
        view.addSubview(containerView)

        NSLayoutConstraint.activate([
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 320),
            containerView.heightAnchor.constraint(equalToConstant: 400)
        ])

        // ScrollView setup for horizontal paging
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.isScrollEnabled = false // We'll control scrolling programmatically
        containerView.addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: containerView.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
        ])

        setupOptionView()
        setupSearchView()
        setupFormView()

        scrollView.addSubview(optionView)
        scrollView.addSubview(searchView)
        scrollView.addSubview(formView)

        // Set up constraints for the three views inside scroll view
        NSLayoutConstraint.activate([
            // Option view constraints
            optionView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            optionView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            optionView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            optionView.widthAnchor.constraint(equalTo: containerView.widthAnchor),
            optionView.heightAnchor.constraint(equalTo: containerView.heightAnchor),
            
            // Search view constraints
            searchView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            searchView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            searchView.leadingAnchor.constraint(equalTo: optionView.trailingAnchor),
            searchView.widthAnchor.constraint(equalTo: containerView.widthAnchor),
            searchView.heightAnchor.constraint(equalTo: containerView.heightAnchor),
            
            // Form view constraints
            formView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            formView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            formView.leadingAnchor.constraint(equalTo: searchView.trailingAnchor),
            formView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            formView.widthAnchor.constraint(equalTo: containerView.widthAnchor),
            formView.heightAnchor.constraint(equalTo: containerView.heightAnchor)
        ])

        // Set scroll view content size for 3 views
        scrollView.contentSize = CGSize(width: 960, height: 400) // 3 * containerView width
    }
    
    // MARK: Keyboard Management
    private func setupKeyboardNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    private func removeKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        
        let keyboardHeight = keyboardFrame.cgRectValue.height
        
        // Only adjust scroll view if the address field (last field) is active
        if addressTextField.isFirstResponder {
            let contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight - 120, right: 0)
            formScrollView.contentInset = contentInset
            formScrollView.scrollIndicatorInsets = contentInset
            
            // Scroll to show the address field and submit button
            let addressFieldFrame = addressTextField.convert(addressTextField.bounds, to: formScrollView)
            let submitButtonFrame = saveAndProceedButton.convert(saveAndProceedButton.bounds, to: formScrollView)
            let combinedFrame = addressFieldFrame.union(submitButtonFrame)
            formScrollView.scrollRectToVisible(combinedFrame, animated: true)
        }
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        // Reset form scroll view content inset
        formScrollView.contentInset = UIEdgeInsets.zero
        formScrollView.scrollIndicatorInsets = UIEdgeInsets.zero
    }
    
    // MARK: Tap Gesture for Keyboard Dismiss
    private func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    private func setupOptionView() {
        optionView.translatesAutoresizingMaskIntoConstraints = false
        
        let newButton = UIButton(type: .system)
        newButton.setTitle("New Patient", for: .normal)
        newButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        newButton.backgroundColor = .systemBlue
        newButton.setTitleColor(.white, for: .normal)
        newButton.layer.cornerRadius = 8
        newButton.addTarget(self, action: #selector(newPatientTapped), for: .touchUpInside)

        let existingButton = UIButton(type: .system)
        existingButton.setTitle("Existing Patient", for: .normal)
        existingButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        existingButton.backgroundColor = .systemGreen
        existingButton.setTitleColor(.white, for: .normal)
        existingButton.layer.cornerRadius = 8
        existingButton.addTarget(self, action: #selector(existingPatientTapped), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [newButton, existingButton])
        stack.axis = .vertical
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        optionView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: optionView.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: optionView.centerYAnchor),
            newButton.heightAnchor.constraint(equalToConstant: 50),
            existingButton.heightAnchor.constraint(equalToConstant: 50),
            newButton.widthAnchor.constraint(equalToConstant: 200),
            existingButton.widthAnchor.constraint(equalToConstant: 200)
        ])
    }

    private func setupSearchView() {
        searchView.translatesAutoresizingMaskIntoConstraints = false
        searchBar.delegate = self
        searchBar.placeholder = "Search for a patient"

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "PatientCell")

        // Add a back button
        let backButton = UIButton(type: .system)
        backButton.setTitle("← Back", for: .normal)
        backButton.addTarget(self, action: #selector(backToOptionsFromSearch), for: .touchUpInside)

        searchBar.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        backButton.translatesAutoresizingMaskIntoConstraints = false
        
        searchView.addSubview(backButton)
        searchView.addSubview(searchBar)
        searchView.addSubview(tableView)

        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: searchView.topAnchor, constant: 10),
            backButton.leadingAnchor.constraint(equalTo: searchView.leadingAnchor, constant: 10),
            
            searchBar.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 10),
            searchBar.leadingAnchor.constraint(equalTo: searchView.leadingAnchor, constant: 10),
            searchBar.trailingAnchor.constraint(equalTo: searchView.trailingAnchor, constant: -10),

            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 10),
            tableView.leadingAnchor.constraint(equalTo: searchView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: searchView.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: searchView.bottomAnchor)
        ])
    }
    
    private func setupFormView() {
        formView.translatesAutoresizingMaskIntoConstraints = false
        
        // Setup form scroll view
        formScrollView.translatesAutoresizingMaskIntoConstraints = false
        formScrollView.keyboardDismissMode = .onDrag // Dismiss keyboard when scrolling
        formContentView.translatesAutoresizingMaskIntoConstraints = false
        
        // Setup text fields
        setupTextField(firstNameTextField, placeholder: "First Name")
        setupTextField(lastNameTextField, placeholder: "Last Name")
        setupTextField(ageTextField, placeholder: "Age", keyboardType: .numberPad)
        setupTextField(emailTextField, placeholder: "Email", keyboardType: .emailAddress)
        setupTextField(phoneTextField, placeholder: "Phone", keyboardType: .phonePad)
        setupTextField(addressTextField, placeholder: "Address")
        
        // Setup save button
        saveAndProceedButton.setTitle("Save & Proceed", for: .normal)
        saveAndProceedButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        saveAndProceedButton.backgroundColor = .systemBlue
        saveAndProceedButton.setTitleColor(.white, for: .normal)
        saveAndProceedButton.layer.cornerRadius = 8
        saveAndProceedButton.translatesAutoresizingMaskIntoConstraints = false
        saveAndProceedButton.addTarget(self, action: #selector(saveAndProceedTapped), for: .touchUpInside)
        
        // Add a back button for form
        let formBackButton = UIButton(type: .system)
        formBackButton.setTitle("← Back", for: .normal)
        formBackButton.addTarget(self, action: #selector(backToOptionsFromForm), for: .touchUpInside)
        formBackButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Add subviews
        formView.addSubview(formBackButton)
        formView.addSubview(formScrollView)
        formScrollView.addSubview(formContentView)
        
        formContentView.addSubview(firstNameTextField)
        formContentView.addSubview(lastNameTextField)
        formContentView.addSubview(ageTextField)
        formContentView.addSubview(emailTextField)
        formContentView.addSubview(phoneTextField)
        formContentView.addSubview(addressTextField)
        formContentView.addSubview(saveAndProceedButton)
        
        NSLayoutConstraint.activate([
            // Back button
            formBackButton.topAnchor.constraint(equalTo: formView.topAnchor, constant: 10),
            formBackButton.leadingAnchor.constraint(equalTo: formView.leadingAnchor, constant: 10),
            
            // Form scroll view
            formScrollView.topAnchor.constraint(equalTo: formBackButton.bottomAnchor, constant: 10),
            formScrollView.leadingAnchor.constraint(equalTo: formView.leadingAnchor),
            formScrollView.trailingAnchor.constraint(equalTo: formView.trailingAnchor),
            formScrollView.bottomAnchor.constraint(equalTo: formView.bottomAnchor),
            
            // Form content view
            formContentView.topAnchor.constraint(equalTo: formScrollView.topAnchor),
            formContentView.leadingAnchor.constraint(equalTo: formScrollView.leadingAnchor),
            formContentView.trailingAnchor.constraint(equalTo: formScrollView.trailingAnchor),
            formContentView.bottomAnchor.constraint(equalTo: formScrollView.bottomAnchor),
            formContentView.widthAnchor.constraint(equalTo: formScrollView.widthAnchor),
            
            // Form fields
            firstNameTextField.topAnchor.constraint(equalTo: formContentView.topAnchor, constant: 20),
            firstNameTextField.leadingAnchor.constraint(equalTo: formContentView.leadingAnchor, constant: 20),
            firstNameTextField.trailingAnchor.constraint(equalTo: formContentView.trailingAnchor, constant: -20),
            firstNameTextField.heightAnchor.constraint(equalToConstant: 40),
            
            lastNameTextField.topAnchor.constraint(equalTo: firstNameTextField.bottomAnchor, constant: 15),
            lastNameTextField.leadingAnchor.constraint(equalTo: formContentView.leadingAnchor, constant: 20),
            lastNameTextField.trailingAnchor.constraint(equalTo: formContentView.trailingAnchor, constant: -20),
            lastNameTextField.heightAnchor.constraint(equalToConstant: 40),
            
            ageTextField.topAnchor.constraint(equalTo: lastNameTextField.bottomAnchor, constant: 15),
            ageTextField.leadingAnchor.constraint(equalTo: formContentView.leadingAnchor, constant: 20),
            ageTextField.trailingAnchor.constraint(equalTo: formContentView.trailingAnchor, constant: -20),
            ageTextField.heightAnchor.constraint(equalToConstant: 40),
            
            emailTextField.topAnchor.constraint(equalTo: ageTextField.bottomAnchor, constant: 15),
            emailTextField.leadingAnchor.constraint(equalTo: formContentView.leadingAnchor, constant: 20),
            emailTextField.trailingAnchor.constraint(equalTo: formContentView.trailingAnchor, constant: -20),
            emailTextField.heightAnchor.constraint(equalToConstant: 40),
            
            phoneTextField.topAnchor.constraint(equalTo: emailTextField.bottomAnchor, constant: 15),
            phoneTextField.leadingAnchor.constraint(equalTo: formContentView.leadingAnchor, constant: 20),
            phoneTextField.trailingAnchor.constraint(equalTo: formContentView.trailingAnchor, constant: -20),
            phoneTextField.heightAnchor.constraint(equalToConstant: 40),
            
            addressTextField.topAnchor.constraint(equalTo: phoneTextField.bottomAnchor, constant: 15),
            addressTextField.leadingAnchor.constraint(equalTo: formContentView.leadingAnchor, constant: 20),
            addressTextField.trailingAnchor.constraint(equalTo: formContentView.trailingAnchor, constant: -20),
            addressTextField.heightAnchor.constraint(equalToConstant: 40),
            
            saveAndProceedButton.topAnchor.constraint(equalTo: addressTextField.bottomAnchor, constant: 30),
            saveAndProceedButton.leadingAnchor.constraint(equalTo: formContentView.leadingAnchor, constant: 20),
            saveAndProceedButton.trailingAnchor.constraint(equalTo: formContentView.trailingAnchor, constant: -20),
            saveAndProceedButton.heightAnchor.constraint(equalToConstant: 50),
            saveAndProceedButton.bottomAnchor.constraint(equalTo: formContentView.bottomAnchor, constant: -20)
        ])
    }
    
    private func setupTextField(_ textField: UITextField, placeholder: String, keyboardType: UIKeyboardType = .default) {
        textField.placeholder = placeholder
        textField.borderStyle = .roundedRect
        textField.keyboardType = keyboardType
        textField.font = UIFont.systemFont(ofSize: 16)
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.returnKeyType = .next
        textField.delegate = self
        
        // Add toolbar with Done button for number pad keyboards
        if keyboardType == .numberPad || keyboardType == .phonePad {
            let toolbar = UIToolbar()
            toolbar.sizeToFit()
            let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissKeyboard))
            let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
            toolbar.setItems([flexSpace, doneButton], animated: false)
            textField.inputAccessoryView = toolbar
        }
    }
    
    private func resizeContainerForForm() {
        // Animate container to larger size for form
        UIView.animate(withDuration: 0.1) {
            self.containerView.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        }
    }
    
    private func resetContainerSize() {
        // Reset container to original size
        UIView.animate(withDuration: 0.1) {
            self.containerView.transform = CGAffineTransform.identity
        }
    }

    // MARK: Actions
    @objc private func newPatientTapped() {
        // First slide to form view, then resize
        UIView.animate(withDuration: 0.3) {
            self.scrollView.setContentOffset(CGPoint(x: 640, y: 0), animated: false)
        } completion: { _ in
            self.resizeContainerForForm()
        }
    }

    @objc private func existingPatientTapped() {
        // Slide scrollView to show searchView
        UIView.animate(withDuration: 0.3) {
            self.scrollView.setContentOffset(CGPoint(x: 320, y: 0), animated: false)
        }
    }
    
    @objc private func backToOptionsFromSearch() {
        // Dismiss keyboard first
        view.endEditing(true)
        
        // Slide back to option view
        UIView.animate(withDuration: 0.3) {
            self.scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
        }
    }
    
    @objc private func backToOptionsFromForm() {
        // Dismiss keyboard first
        view.endEditing(true)
        
        // First reset size, then slide back to option view
        resetContainerSize()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            UIView.animate(withDuration: 0.3) {
                self.scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
            }
        }
    }
    
    @objc private func saveAndProceedTapped() {
        // Dismiss keyboard first
        view.endEditing(true)
        
        // Validate required fields
        guard let firstName = firstNameTextField.text, !firstName.isEmpty else {
            showAlert(message: "First name is required")
            return
        }
        
        let lastName = lastNameTextField.text ?? ""
        let age = Int(ageTextField.text ?? "")
        let email = emailTextField.text?.isEmpty == false ? emailTextField.text : nil
        let phone = phoneTextField.text?.isEmpty == false ? phoneTextField.text : nil
        let address = addressTextField.text?.isEmpty == false ? addressTextField.text : nil
        
        let newPatient = Patient(
            firstName: firstName,
            lastName: lastName,
            age: age,
            email: email,
            phone: phone,
            address: address,
            eyeData: nil
        )
        
        // Save the patient and proceed to camera
        resetContainerSize()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.dismiss(animated: true) {
                self.onPatientSelected?(newPatient)
            }
        }
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Validation Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // MARK: SearchBar
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

    // MARK: Table
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filteredPatients.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PatientCell", for: indexPath)
        let patient = filteredPatients[indexPath.row]
        cell.textLabel?.text = "\(patient.firstName) \(patient.lastName)"
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let selected = filteredPatients[indexPath.row]
        dismiss(animated: true) {
            self.onPatientSelected?(selected)
        }
    }
}

// MARK: UITextFieldDelegate
extension PatientPickerViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Move to next text field or dismiss keyboard
        switch textField {
        case firstNameTextField:
            lastNameTextField.becomeFirstResponder()
        case lastNameTextField:
            ageTextField.becomeFirstResponder()
        case ageTextField:
            emailTextField.becomeFirstResponder()
        case emailTextField:
            phoneTextField.becomeFirstResponder()
        case phoneTextField:
            addressTextField.becomeFirstResponder()
        case addressTextField:
            textField.resignFirstResponder()
        default:
            textField.resignFirstResponder()
        }
        return true
    }
}
