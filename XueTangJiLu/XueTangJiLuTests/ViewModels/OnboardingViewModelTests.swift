//
//  OnboardingViewModelTests.swift
//  XueTangJiLuTests
//
//  Created by AI Assistant on 2026/2/23.
//

import Testing
@testable import XueTangJiLu

@MainActor
struct OnboardingViewModelTests {
    
    // MARK: - 初始状态测试
    
    @Test("初始状态 - 步骤0")
    func testInitialState() {
        let viewModel = OnboardingViewModel()
        
        #expect(viewModel.currentStep == 0)
        #expect(viewModel.totalSteps == 4)
        #expect(viewModel.isLastStep == false)
    }
    
    @Test("初始状态 - 默认单位")
    func testInitialUnit() {
        let viewModel = OnboardingViewModel()
        
        #expect(viewModel.selectedUnit == .mmolL)
    }
    
    // MARK: - 步骤导航测试
    
    @Test("下一步导航")
    func testNextStep() {
        let viewModel = OnboardingViewModel()
        
        viewModel.nextStep()
        #expect(viewModel.currentStep == 1)
        
        viewModel.nextStep()
        #expect(viewModel.currentStep == 2)
        
        viewModel.nextStep()
        #expect(viewModel.currentStep == 3)
        #expect(viewModel.isLastStep == true)
    }
    
    @Test("上一步导航")
    func testPreviousStep() {
        let viewModel = OnboardingViewModel()
        
        viewModel.currentStep = 3
        
        viewModel.previousStep()
        #expect(viewModel.currentStep == 2)
        
        viewModel.previousStep()
        #expect(viewModel.currentStep == 1)
        
        viewModel.previousStep()
        #expect(viewModel.currentStep == 0)
    }
    
    @Test("不能超过最后一步")
    func testCannotExceedLastStep() {
        let viewModel = OnboardingViewModel()
        
        // 快速到达最后一步
        while !viewModel.isLastStep {
            viewModel.nextStep()
        }
        
        let lastStep = viewModel.currentStep
        viewModel.nextStep()
        
        #expect(viewModel.currentStep == lastStep)
    }
    
    @Test("不能低于第一步")
    func testCannotGoBelowFirstStep() {
        let viewModel = OnboardingViewModel()
        
        #expect(viewModel.currentStep == 0)
        
        viewModel.previousStep()
        
        #expect(viewModel.currentStep == 0)
    }
    
    // MARK: - 单位选择测试
    
    @Test("单位选择 - mmol/L")
    func testSelectMmolL() {
        let viewModel = OnboardingViewModel()
        
        viewModel.selectedUnit = .mmolL
        
        #expect(viewModel.selectedUnit == .mmolL)
    }
    
    @Test("单位选择 - mg/dL")
    func testSelectMgdL() {
        let viewModel = OnboardingViewModel()
        
        viewModel.selectedUnit = .mgdL
        
        #expect(viewModel.selectedUnit == .mgdL)
    }
    
    // MARK: - 最后一步判断测试
    
    @Test("最后一步判断")
    func testIsLastStep() {
        let viewModel = OnboardingViewModel()
        
        #expect(viewModel.isLastStep == false)
        
        viewModel.currentStep = 3 // 最后一步（总共4步，索引从0开始）
        
        #expect(viewModel.isLastStep == true)
    }
}
