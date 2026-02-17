import { Pressable, StyleSheet, Text, View } from "react-native";

export type ConversationListItem = {
  id: string;
  title: string;
  preview: string;
  statusLabel: string;
  caseId: string | null;
  updatedAtText: string;
};

type ConversationListScreenProps = {
  session: ConversationListItem;
  onSelectSession: (sessionId: string) => void;
};

export function ConversationListScreen({ session, onSelectSession }: ConversationListScreenProps) {
  return (
    <View style={styles.screen}>
      <View style={styles.header}>
        <Text style={styles.headerTitle}>대화 목록</Text>
        <Text style={styles.headerSubtitle}>최근 세션을 눌러 상담으로 복귀하세요.</Text>
      </View>

      <Pressable
        onPress={() => onSelectSession(session.id)}
        style={({ pressed }) => [styles.sessionCard, pressed && styles.sessionCardPressed]}
      >
        <View style={styles.sessionTopRow}>
          <Text style={styles.sessionTitle}>{session.title}</Text>
          <Text style={styles.sessionUpdatedAt}>{session.updatedAtText}</Text>
        </View>

        <Text style={styles.sessionPreview} numberOfLines={2}>
          {session.preview}
        </Text>

        <View style={styles.sessionMetaRow}>
          <View style={styles.statusBadge}>
            <Text style={styles.statusBadgeText}>{session.statusLabel}</Text>
          </View>
          <Text style={styles.caseIdText} numberOfLines={1}>
            {session.caseId ? `case: ${session.caseId}` : "case: 생성 전"}
          </Text>
        </View>
      </Pressable>
    </View>
  );
}

const styles = StyleSheet.create({
  screen: {
    flex: 1,
    backgroundColor: "#f8fafc",
    paddingHorizontal: 20,
    paddingTop: 76,
  },
  header: {
    marginBottom: 16,
  },
  headerTitle: {
    color: "#0f172a",
    fontSize: 24,
    lineHeight: 30,
    fontWeight: "700",
  },
  headerSubtitle: {
    marginTop: 6,
    color: "#64748b",
    fontSize: 14,
    lineHeight: 20,
    fontWeight: "500",
  },
  sessionCard: {
    borderRadius: 18,
    borderWidth: 1,
    borderColor: "#dbeafe",
    backgroundColor: "#ffffff",
    paddingHorizontal: 14,
    paddingVertical: 14,
    gap: 10,
  },
  sessionCardPressed: {
    opacity: 0.8,
  },
  sessionTopRow: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    gap: 8,
  },
  sessionTitle: {
    flex: 1,
    color: "#0f172a",
    fontSize: 16,
    lineHeight: 22,
    fontWeight: "700",
  },
  sessionUpdatedAt: {
    color: "#94a3b8",
    fontSize: 12,
    lineHeight: 16,
    fontWeight: "500",
  },
  sessionPreview: {
    color: "#334155",
    fontSize: 14,
    lineHeight: 20,
    fontWeight: "500",
  },
  sessionMetaRow: {
    flexDirection: "row",
    alignItems: "center",
    gap: 8,
  },
  statusBadge: {
    borderRadius: 999,
    borderWidth: 1,
    borderColor: "#bfdbfe",
    backgroundColor: "#eff6ff",
    paddingHorizontal: 8,
    paddingVertical: 4,
  },
  statusBadgeText: {
    color: "#1e40af",
    fontSize: 12,
    lineHeight: 14,
    fontWeight: "700",
  },
  caseIdText: {
    flex: 1,
    color: "#64748b",
    fontSize: 12,
    lineHeight: 16,
    fontWeight: "500",
  },
});
