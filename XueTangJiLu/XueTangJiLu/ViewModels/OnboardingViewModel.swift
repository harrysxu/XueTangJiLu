//
//  OnboardingViewModel.swift
//  XueTangJiLu
//
//  Created by 徐晓龙 on 2026/2/12.
//

import Foundation
import Observation

/// 引导流程状态管理
@Observable
final class OnboardingViewModel {

    /// 当前步骤 (0: 欢迎, 1: 单位选择, 2: 科普, 3: HealthKit)
    var currentStep: Int = 0

    /// 用户选择的血糖单位
    var selectedUnit: GlucoseUnit = .systemDefault

    /// 总步骤数
    let totalSteps = 4

    /// 是否为最后一步
    var isLastStep: Bool {
        currentStep == totalSteps - 1
    }

    /// 进入下一步
    func nextStep() {
        if currentStep < totalSteps - 1 {
            currentStep += 1
        }
    }

    /// 返回上一步
    func previousStep() {
        if currentStep > 0 {
            currentStep -= 1
        }
    }
}
