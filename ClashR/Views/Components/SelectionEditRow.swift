// SelectionEditView.swift
import SwiftUI

// MARK: - 主页面使用的行组件（一行调用）
public struct SelectionEditRow: View {
    public let title: String
    public let options: [String]
    public let values: [String]
    public let currentValue: String
    public let onSelection: (String) -> Void

    public init(
        title: String,
        options: [String],
        values: [String] = [],
        currentValue: String,
        onSelection: @escaping (String) -> Void
    ) {
        self.title = title
        self.options = options
        self.values = values.isEmpty ? options : values
        self.currentValue = currentValue
        self.onSelection = onSelection
    }

    public var body: some View {
        NavigationLink {
            SelectionPageView(
                title: title,
                options: options,
                values: values,
                currentValue: currentValue,
                onSelection: onSelection
            )
        } label: {
            HStack {
                Text(title)
                Spacer()
                Text(displayValue)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var displayValue: String {
        if let index = values.firstIndex(of: currentValue) {
            return options[index]
        }
        return currentValue
    }
}

// MARK: - 选择页面（独立，避免导航封装问题）
private struct SelectionPageView: View {
    let title: String
    let options: [String]
    let values: [String]
    let currentValue: String
    let onSelection: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            ForEach(0..<options.count, id: \.self) { i in
                HStack {
                    Text(options[i])
                    Spacer()
                    if values[i] == currentValue {
                        Image(systemName: "checkmark")
                            .foregroundColor(.accentColor)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    onSelection(values[i])
                    dismiss()
                }
            }
        }
        // ✅ 关键：用 .navigationBarTitle 避免标题延迟
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

public struct TextEditRow: View {
    public let title: String
    public let value: String
    public let placeholder: String
    public let keyboardType: UIKeyboardType
    public let onSave: (String) -> Void

    public init(
        title: String,
        value: String,
        placeholder: String? = nil,
        keyboardType: UIKeyboardType = .default,
        onSave: @escaping (String) -> Void
    ) {
        self.title = title
        self.value = value
        self.placeholder = placeholder ?? title
        self.keyboardType = keyboardType
        self.onSave = onSave
    }

    public var body: some View {
        NavigationLink {
            TextEditPage(
                title: title,
                initialValue: value,
                placeholder: placeholder,
                keyboardType: keyboardType,
                onSave: onSave
            )
        } label: {
            HStack {
                Text(title)
                Spacer()
                Text(value.isEmpty ? placeholder : value)
                    .foregroundColor(value.isEmpty ? .secondary : .primary)
            }
        }
    }
}

private struct TextEditPage: View {
    let title: String
    let placeholder: String
    let keyboardType: UIKeyboardType
    let onSave: (String) -> Void
    @State private var text: String
    @Environment(\.dismiss) private var dismiss

    init(
        title: String,
        initialValue: String,
        placeholder: String,
        keyboardType: UIKeyboardType,
        onSave: @escaping (String) -> Void
    ) {
        self.title = title
        self.placeholder = placeholder
        self.keyboardType = keyboardType
        self.onSave = onSave
        self._text = State(initialValue: initialValue)
    }

    var body: some View {
        Form {
            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
        }
        .navigationBarTitle(title, displayMode: .inline) // ✅ 无延迟
        .onDisappear {
            onSave(text)
        }
    }
}

// IntEditRow.swift
import SwiftUI

public struct IntEditRow: View {
    public let title: String
    public let value: Int
    public let range: ClosedRange<Int>
    public let onSave: (Int) -> Void

    public init(
        title: String,
        value: Int,
        range: ClosedRange<Int> = 1...65535,
        onSave: @escaping (Int) -> Void
    ) {
        self.title = title
        self.value = value
        self.range = range
        self.onSave = onSave
    }

    public var body: some View {
        NavigationLink {
            IntEditPage(
                title: title,
                initialValue: value,
                range: range,
                onSave: onSave
            )
        } label: {
            HStack {
                Text(title)
                Spacer()
                Text("\(value)")
                    .foregroundColor(.primary)
            }
        }
    }
}

private struct IntEditPage: View {
    let title: String
    let range: ClosedRange<Int>
    let onSave: (Int) -> Void
    @State private var text: String
    @Environment(\.dismiss) private var dismiss

    init(
        title: String,
        initialValue: Int,
        range: ClosedRange<Int>,
        onSave: @escaping (Int) -> Void
    ) {
        self.title = title
        self.range = range
        self.onSave = onSave
        self._text = State(initialValue: "\(initialValue)")
    }

    var body: some View {
        Form {
            TextField(title, text: $text)
                .keyboardType(.numberPad)
                .onChange(of: text) { newValue in
                    // 实时过滤非数字字符
                    let filtered = newValue.filter { $0.isNumber }
                    if filtered != newValue {
                        text = filtered
                    }
                }
                .onSubmit {
                    saveAndDismiss()
                }
        }
        .navigationBarTitle(title, displayMode: .inline)
        .onDisappear {
            saveAndDismiss()
        }
    }

    private func saveAndDismiss() {
        if let intValue = Int(text), range.contains(intValue) {
            onSave(intValue)
        } else if !text.isEmpty {
            // 如果输入无效，保存边界值
            let clamped = min(max(Int(text) ?? range.lowerBound, range.lowerBound), range.upperBound)
            onSave(clamped)
        }
        // 如果为空，保留原值（由 initialValue 保证）
    }
}
