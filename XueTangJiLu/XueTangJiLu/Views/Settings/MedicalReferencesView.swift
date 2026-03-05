//
//  MedicalReferencesView.swift
//  XueTangJiLu
//
//  Created by AI Assistant on 2026/3/5.
//

import SwiftUI

/// 医学参考来源汇总页面
struct MedicalReferencesView: View {
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppConstants.Spacing.xl) {
                headerSection
                
                VStack(spacing: AppConstants.Spacing.md) {
                    ForEach(MedicalReferenceLibrary.references) { ref in
                        referenceCard(ref)
                    }
                }
                
                disclaimerFooter
            }
            .padding(AppConstants.Spacing.lg)
        }
        .background(Color.pageBackground)
        .navigationTitle(String(localized: "references.title"))
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(spacing: AppConstants.Spacing.md) {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 44))
                .foregroundStyle(.blue)
            
            Text(String(localized: "references.header"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, AppConstants.Spacing.md)
    }
    
    // MARK: - Reference Card
    
    private func referenceCard(_ ref: MedicalReferenceLibrary.Reference) -> some View {
        VStack(alignment: .leading, spacing: AppConstants.Spacing.sm) {
            Text(ref.title)
                .font(.subheadline.weight(.semibold))
            
            Text(ref.detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(2)
            
            if let urlString = ref.url, let url = URL(string: urlString) {
                Link(destination: url) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption)
                        Text(String(localized: "references.view_source"))
                            .font(.caption)
                    }
                    .foregroundStyle(.blue)
                }
                .padding(.top, 2)
            }
        }
        .padding(AppConstants.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card)
                .fill(Color.cardBackground)
        )
    }
    
    // MARK: - Disclaimer Footer
    
    private var disclaimerFooter: some View {
        HStack(alignment: .top, spacing: AppConstants.Spacing.sm) {
            Image(systemName: "info.circle.fill")
                .font(.callout)
                .foregroundStyle(.orange)
            
            Text(String(localized: "references.disclaimer"))
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(AppConstants.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.orange.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    NavigationStack {
        MedicalReferencesView()
    }
}
