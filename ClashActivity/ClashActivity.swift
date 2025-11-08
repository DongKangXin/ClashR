//
//  ClashWidgets.swift
//  ClashR
//
//  Created by 董康鑫 on 2025/10/24.
//

import SwiftUI
import WidgetKit


@main
struct ClashActivity: WidgetBundle {
    var body: some Widget {
        ClashActivityLiveActivity()
        // 如果还有普通小组件，可一起返回
        // MyNormalWidget()
    }
}
