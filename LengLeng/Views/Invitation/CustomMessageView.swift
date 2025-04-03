import SwiftUI

struct CustomMessageView: View {
    @Binding var message: String
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTemplate: MessageTemplate?
    @State private var showingPreview = false
    
    private let templates: [MessageTemplate] = [
        MessageTemplate(
            title: "School Connection",
            message: "Someone at your school picked you on LengLeng 🔥 Find out who!"
        ),
        MessageTemplate(
            title: "Social Proof",
            message: "5 people from your school have rated you on LengLeng. See what they said!"
        ),
        MessageTemplate(
            title: "Crush Hint",
            message: "Your crush might be waiting for you on LengLeng 👀"
        ),
        MessageTemplate(
            title: "Premium",
            message: "Someone you know just gave you a flame on LengLeng 🔥 They're waiting for you!"
        )
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Message Templates
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Message Templates")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            ForEach(templates) { template in
                                TemplateButton(
                                    template: template,
                                    isSelected: selectedTemplate?.id == template.id,
                                    action: { selectTemplate(template) }
                                )
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(15)
                        
                        // Custom Message
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Custom Message")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            TextEditor(text: $message)
                                .frame(height: 100)
                                .padding(8)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(10)
                                .foregroundColor(.white)
                            
                            Text("\(message.count)/200 characters")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(15)
                        
                        // Preview Button
                        Button(action: { showingPreview = true }) {
                            HStack {
                                Image(systemName: "eye.fill")
                                Text("Preview Message")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(15)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Customize Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingPreview) {
                MessagePreviewView(message: message)
            }
        }
    }
    
    private func selectTemplate(_ template: MessageTemplate) {
        selectedTemplate = template
        message = template.message
    }
}

struct MessageTemplate: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

struct TemplateButton: View {
    let template: MessageTemplate
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(template.title)
                        .font(.subheadline)
                        .foregroundColor(.white)
                    Text(template.message)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
            }
            .padding()
            .background(Color.gray.opacity(0.2))
            .cornerRadius(10)
        }
    }
}

struct MessagePreviewView: View {
    let message: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    // Message Preview
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Message Preview")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text(message)
                            .font(.body)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(10)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(15)
                    
                    // How it will look
                    VStack(alignment: .leading, spacing: 10) {
                        Text("How it will look")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.title)
                                .foregroundColor(.gray)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("You")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                Text(message)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(15)
                }
                .padding()
            }
            .navigationTitle("Message Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
} 