a!formLayout(
  titleBar: "Escalate Case",
  contents: {
    a!textField(label: "Case", value: "SO-" & ri!caseId, readOnly: true),
    a!paragraphField(
      label: "Escalation reason",
      instructions: "Required. Recorded as a case comment and summarised on the audit trail.",
      required: true,
      height: "MEDIUM",
      value: ri!reason,
      saveInto: ri!reason
    )
  },
  buttons: a!buttonLayout(
    primaryButtons: a!buttonWidget(label: "Escalate", submit: true, style: "SOLID")
  )
)
