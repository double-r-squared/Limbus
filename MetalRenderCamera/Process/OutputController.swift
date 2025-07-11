//
//  File.swift
//  Metal Camera
//
//  Created by Nate  on 7/9/25.
//  Copyright © 2025 Old Yellow Bricks. All rights reserved.
//

import UIKit

class OutputViewController: UIViewController {
    
    // MARK: - Properties
    private var values: [Int] = []
    private var gridSize: Int = 4 // Default 4x4 grid (mutable)
    private var cubeViews: [UIView] = []
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // MARK: - Initialization
    init(values: [Int], gridSize: Int = 4) {
        self.values = values
        self.gridSize = gridSize
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        createGrid()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .white
        title = "Value Grid"
        
        // Configure scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }
    
    // MARK: - Grid Creation
    private func createGrid() {
        // Clear previous cubes
        cubeViews.forEach { $0.removeFromSuperview() }
        cubeViews.removeAll()
        
        let spacing: CGFloat = 16
        let cubeSize = (view.bounds.width - CGFloat(gridSize + 1) * spacing) / CGFloat(gridSize)
        
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                let index = row * gridSize + col
                let value = index < values.count ? values[index] : 0
                
                let cube = createCube(value: value, size: cubeSize)
                cube.frame = CGRect(
                    x: spacing + CGFloat(col) * (cubeSize + spacing),
                    y: spacing + CGFloat(row) * (cubeSize + spacing),
                    width: cubeSize,
                    height: cubeSize
                )
                
                contentView.addSubview(cube)
                cubeViews.append(cube)
            }
        }
        
        // Update content size
        let totalHeight = CGFloat(gridSize) * (cubeSize + spacing) + spacing
        contentView.heightAnchor.constraint(equalToConstant: totalHeight).isActive = true
    }
    
    private func createCube(value: Int, size: CGFloat) -> UIView {
        let cube = UIView()
        cube.backgroundColor = .systemBlue
        cube.layer.cornerRadius = 8
        cube.layer.masksToBounds = true
        
        // Add value label
        let label = UILabel()
        label.text = "\(value)"
        label.textColor = .white
        label.font = UIFont.boldSystemFont(ofSize: size * 0.4)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        cube.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: cube.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: cube.centerYAnchor)
        ])
        
        return cube
    }
    
    // MARK: - Public Methods
    func updateGrid(with values: [Int], gridSize: Int? = nil) {
        if let newSize = gridSize {
            self.gridSize = newSize
        }
        self.values = values
        createGrid()
    }
}
