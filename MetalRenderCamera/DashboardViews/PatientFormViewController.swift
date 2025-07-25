import UIKit
import SwiftData

class PatientFormViewController: UIViewController, UITextFieldDelegate {
    private let modelContext: ModelContext
    var onPatientSaved: (() -> Void)?
    
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.keyboardDismissMode = .onDrag
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
        tf.font = UIFont.systemFont(ofSize: 16)
        tf.returnKeyType = .next
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    private let lastNameTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Last Name"
        tf.borderStyle = .roundedRect
        tf.font = UIFont.systemFont(ofSize: 16)
        tf.returnKeyType = .next
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    private let ageTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Age"
        tf.borderStyle = .roundedRect
        tf.keyboardType = .numberPad
        tf.font = UIFont.systemFont(ofSize: 16)
        tf.returnKeyType = .next
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    private let emailTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Email"
        tf.borderStyle = .roundedRect
        tf.keyboardType = .emailAddress
        tf.font = UIFont.systemFont(ofSize: 16)
        tf.returnKeyType = .next
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    private let phoneTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Phone"
        tf.borderStyle = .roundedRect
        tf.keyboardType = .phonePad
        tf.font = UIFont.systemFont(ofSize: 16)
        tf.returnKeyType = .next
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    private let addressTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Address"
        tf.borderStyle = .roundedRect
        tf.font = UIFont.systemFont(ofSize: 16)
        tf.returnKeyType = .next
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    private let leftEyeNotesTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Left Eye Notes"
        tf.borderStyle = .roundedRect
        tf.font = UIFont.systemFont(ofSize: 16)
        tf.returnKeyType = .next
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    private let rightEyeNotesTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Right Eye Notes"
        tf.borderStyle = .roundedRect
        tf.font = UIFont.systemFont(ofSize: 16)
        tf.returnKeyType = .done
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    private let saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Save", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let saveAndProceedButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Save and Proceed", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        button.backgroundColor = .systemGreen
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
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
        view.backgroundColor = .systemBackground
        title = "New Patient"
        
        setupUI()
        setupActions()
        setupKeyboardNotifications()
        setupTextFields()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeKeyboardNotifications()
    }
    
    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(firstNameTextField)
        contentView.addSubview(lastNameTextField)
        contentView.addSubview(ageTextField)
        contentView.addSubview(emailTextField)
        contentView.addSubview(phoneTextField)
        contentView.addSubview(addressTextField)
        contentView.addSubview(leftEyeNotesTextField)
        contentView.addSubview(rightEyeNotesTextField)
        contentView.addSubview(saveButton)
        contentView.addSubview(saveAndProceedButton)
        contentView.addSubview(cancelButton)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
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
            
            leftEyeNotesTextField.topAnchor.constraint(equalTo: addressTextField.bottomAnchor, constant: 16),
            leftEyeNotesTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            leftEyeNotesTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            leftEyeNotesTextField.heightAnchor.constraint(equalToConstant: 44),
            
            rightEyeNotesTextField.topAnchor.constraint(equalTo: leftEyeNotesTextField.bottomAnchor, constant: 16),
            rightEyeNotesTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            rightEyeNotesTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            rightEyeNotesTextField.heightAnchor.constraint(equalToConstant: 44),
            
            saveButton.topAnchor.constraint(equalTo: rightEyeNotesTextField.bottomAnchor, constant: 30),
            saveButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            saveButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            saveButton.heightAnchor.constraint(equalToConstant: 50),
            
            saveAndProceedButton.topAnchor.constraint(equalTo: saveButton.bottomAnchor, constant: 12),
            saveAndProceedButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            saveAndProceedButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            saveAndProceedButton.heightAnchor.constraint(equalToConstant: 50),
            
            cancelButton.topAnchor.constraint(equalTo: saveAndProceedButton.bottomAnchor, constant: 12),
            cancelButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            cancelButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            cancelButton.heightAnchor.constraint(equalToConstant: 50),
            cancelButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    private func setupActions() {
        saveButton.addTarget(self, action: #selector(savePatient), for: .touchUpInside)
        saveAndProceedButton.addTarget(self, action: #selector(saveAndProceed), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    private func setupTextFields() {
        firstNameTextField.delegate = self
        lastNameTextField.delegate = self
        ageTextField.delegate = self
        emailTextField.delegate = self
        phoneTextField.delegate = self
        addressTextField.delegate = self
        leftEyeNotesTextField.delegate = self
        rightEyeNotesTextField.delegate = self
        
        // Add toolbar for numberPad and phonePad
        [ageTextField, phoneTextField].forEach { textField in
            let toolbar = UIToolbar()
            toolbar.sizeToFit()
            let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissKeyboard))
            let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
            toolbar.setItems([flexSpace, doneButton], animated: false)
            textField.inputAccessoryView = toolbar
        }
    }
    
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
        let contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight, right: 0)
        scrollView.contentInset = contentInset
        scrollView.scrollIndicatorInsets = contentInset
        
        if let activeField = view.firstResponder {
            let fieldFrame = activeField.convert(activeField.bounds, to: scrollView)
            let buttonFrame = saveAndProceedButton.convert(saveAndProceedButton.bounds, to: scrollView)
            let combinedFrame = fieldFrame.union(buttonFrame)
            scrollView.scrollRectToVisible(combinedFrame, animated: true)
        }
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        scrollView.contentInset = UIEdgeInsets.zero
        scrollView.scrollIndicatorInsets = UIEdgeInsets.zero
    }
    
    @objc private func savePatient() {
        guard let firstName = firstNameTextField.text, !firstName.isEmpty else {
            showAlert(message: "First name is required")
            return
        }
        
        let lastName = lastNameTextField.text ?? ""
        let age = Int(ageTextField.text ?? "")
        let email = emailTextField.text?.isEmpty == false ? emailTextField.text : nil
        let phone = phoneTextField.text?.isEmpty == false ? phoneTextField.text : nil
        let address = addressTextField.text?.isEmpty == false ? addressTextField.text : nil
        let leftEyeNotes = leftEyeNotesTextField.text?.isEmpty == false ? leftEyeNotesTextField.text : nil
        let rightEyeNotes = rightEyeNotesTextField.text?.isEmpty == false ? rightEyeNotesTextField.text : nil
        
        let eyeData = EyeData(
            leftEyeNotes: leftEyeNotes,
            rightEyeNotes: rightEyeNotes,
            leftEyeImages: ImageStore(eyeType: .left),
            rightEyeImages: ImageStore(eyeType: .right)
        )
        
        let newPatient = Patient(
            firstName: firstName,
            lastName: lastName,
            age: age,
            email: email,
            phone: phone,
            address: address,
            eyeData: eyeData
        )
        
        modelContext.insert(newPatient)
        do {
            try modelContext.save()
            print("Saved patient: \(newPatient)")
            onPatientSaved?()
            dismiss(animated: true)
        } catch {
            showAlert(message: "Failed to save patient: \(error.localizedDescription)")
        }
    }
    
    @objc private func saveAndProceed() {
        guard let firstName = firstNameTextField.text, !firstName.isEmpty else {
            showAlert(message: "First name is required")
            return
        }
        
        let lastName = lastNameTextField.text ?? ""
        let age = Int(ageTextField.text ?? "")
        let email = emailTextField.text?.isEmpty == false ? emailTextField.text : nil
        let phone = phoneTextField.text?.isEmpty == false ? phoneTextField.text : nil
        let address = addressTextField.text?.isEmpty == false ? addressTextField.text : nil
        let leftEyeNotes = leftEyeNotesTextField.text?.isEmpty == false ? leftEyeNotesTextField.text : nil
        let rightEyeNotes = rightEyeNotesTextField.text?.isEmpty == false ? rightEyeNotesTextField.text : nil
        
        let eyeData = EyeData(
            leftEyeNotes: leftEyeNotes,
            rightEyeNotes: rightEyeNotes,
            leftEyeImages: ImageStore(eyeType: .left),
            rightEyeImages: ImageStore(eyeType: .right)
        )
        
        let newPatient = Patient(
            firstName: firstName,
            lastName: lastName,
            age: age,
            email: email,
            phone: phone,
            address: address,
            eyeData: eyeData
        )
        
        modelContext.insert(newPatient)
        do {
            try modelContext.save()
            print("Saved patient: \(newPatient)")
            onPatientSaved?()
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
    
    // MARK: UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
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
            leftEyeNotesTextField.becomeFirstResponder()
        case leftEyeNotesTextField:
            rightEyeNotesTextField.becomeFirstResponder()
        case rightEyeNotesTextField:
            textField.resignFirstResponder()
        default:
            textField.resignFirstResponder()
        }
        return true
    }
}

// MARK: - Extension for Finding First Responder
extension UIView {
    var firstResponder: UIView? {
        if isFirstResponder {
            return self
        }
        for subview in subviews {
            if let responder = subview.firstResponder {
                return responder
            }
        }
        return nil
    }
}
