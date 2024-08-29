//
//  ContentView.swift
//  VTB Deeplinks
//
//  Created by Владимир Тамбовцев on 27.08.2024.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
            // Replace "https://ift-ibrb1-sharing.vtb.ru/i/..." with your desired URL
            WebView(url: URL(string: "https://ift-ibrb1-sharing.vtb.ru/i/paymentSbp/AS10000KVF0LMG3V9TVOOALT90HS2JE2")!)
                .edgesIgnoringSafeArea(.all)
    }
}

#Preview {
    ContentView()
}
