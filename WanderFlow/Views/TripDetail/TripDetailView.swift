import SwiftUI
import SwiftData

struct TripDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    var trip: Trip
    
    @State private var selection: DetailTab = .itinerary
    @State private var isShowingAddMenu: Bool = false
    @State private var isShowingMoreMenu: Bool = false
    @State private var isShowingTripEditor: Bool = false
    @State private var isShowingAddItinerary: Bool = false
    @State private var isShowingAddExpense: Bool = false
    @State private var isConfirmingDelete: Bool = false
    @State private var editingItem: ItineraryItem?
    @State private var quickExpenseNote: String?
    @State private var quickExpenseCategory: String?
    @State private var quickExpenseOccurredAt: Date?
    
    enum DetailTab: String, CaseIterable {
        case itinerary = "行程"
        case expenses = "支出"
        case summary = "汇总"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            TripDetailHeader(trip: trip)
            Picker("视图切换", selection: $selection) {
                ForEach(DetailTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.bottom, 10)
            .background(CuteTheme.background)
            
            if selection == .itinerary {
                TimelineView(trip: trip, editingItineraryItem: $editingItem, onQuickAddExpense: { item in
                    isShowingAddExpense = true
                    quickExpenseNote = item.title
                    quickExpenseOccurredAt = item.date
                    quickExpenseCategory = "餐饮"
                })
            } else if selection == .expenses {
                ExpenseListView(trip: trip)
            } else {
                TripSummaryView(trip: trip)
            }
        }
        .background(CuteTheme.background)
        .navigationTitle(trip.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack {
                    Button {
                        isShowingAddMenu = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    
                    Button {
                        isShowingMoreMenu = true
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .alert("删除这趟旅行？", isPresented: $isConfirmingDelete) {
            Button("删除旅行", role: .destructive) {
                modelContext.delete(trip)
                try? modelContext.save()
                dismiss()
            }
            Button("取消", role: .cancel) {}
        }
        .sheet(isPresented: $isShowingAddMenu) {
            TripDetailAddMenuSheet(
                onAddItinerary: {
                    editingItem = nil
                    isShowingAddItinerary = true
                },
                onAddExpense: {
                    quickExpenseNote = nil
                    quickExpenseOccurredAt = nil
                    quickExpenseCategory = "其他"
                    isShowingAddExpense = true
                }
            )
            .presentationDetents([.height(200)])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isShowingMoreMenu) {
            TripDetailMoreMenuSheet(
                onEditTrip: { isShowingTripEditor = true },
                onDeleteTrip: { isConfirmingDelete = true }
            )
            .presentationDetents([.height(200)])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isShowingTripEditor) { TripEditorSheet(trip: trip) }
        .sheet(isPresented: $isShowingAddItinerary) {
            AddItineraryItemSheet(trip: trip, itemToEdit: editingItem)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $isShowingAddExpense) {
            AddExpenseSheet(trip: trip, defaultNote: quickExpenseNote, defaultCategory: quickExpenseCategory, defaultOccurredAt: quickExpenseOccurredAt)
                .presentationDetents([.medium])
        }
        // 当 editingItem 变化时自动触发 Sheet
        .onChange(of: editingItem) { _, newItem in
            if newItem != nil {
                isShowingAddItinerary = true
            }
        }
    }
}

private struct TripDetailAddMenuSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var onAddItinerary: () -> Void
    var onAddExpense: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            VStack(spacing: 10) {
                TripDetailMenuRow(title: "添加行程", subtitle: "几点去哪儿", systemImage: "mappin.and.ellipse") {
                    dismiss()
                    DispatchQueue.main.async { onAddItinerary() }
                }
                TripDetailMenuRow(title: "记一笔支出", subtitle: "金额与类别", systemImage: "creditcard") {
                    dismiss()
                    DispatchQueue.main.async { onAddExpense() }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 14)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

private struct TripDetailMoreMenuSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var onEditTrip: () -> Void
    var onDeleteTrip: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            VStack(spacing: 10) {
                TripDetailMenuRow(title: "编辑旅行", subtitle: "标题/日期/颜色", systemImage: "pencil") {
                    dismiss()
                    DispatchQueue.main.async { onEditTrip() }
                }
                TripDetailMenuRow(title: "删除旅行", subtitle: "需要二次确认", systemImage: "trash", isDestructive: true) {
                    dismiss()
                    DispatchQueue.main.async { onDeleteTrip() }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 14)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

private struct TripDetailMenuRow: View {
    var title: String
    var subtitle: String
    var systemImage: String
    var isDestructive: Bool = false
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(CuteTheme.gradient)
                        .frame(width: 36, height: 36)
                        .opacity(isDestructive ? 0.6 : 1.0)
                    Image(systemName: systemImage)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(isDestructive ? .red : CuteTheme.accent)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(isDestructive ? .red : .primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
            }
            .padding(14)
            .background(CuteTheme.cardBackground(cornerRadius: 18))
        }
        .buttonStyle(.plain)
    }
}
