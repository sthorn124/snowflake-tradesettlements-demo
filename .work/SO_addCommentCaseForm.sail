a!formLayout(
  titleBar: "Add Comment",
  contents: {
    a!textField(label: "Case", value: "SO-" & ri!caseId, readOnly: true),
    a!paragraphField(
      label: "Comment",
      instructions: "Analyst notes. Kept separate from the audit trail.",
      required: true,
      height: "MEDIUM",
      value: ri!commentText,
      saveInto: ri!commentText
    )
  },
  buttons: a!buttonLayout(
    primaryButtons: a!buttonWidget(label: "Add Comment", submit: true, style: "SOLID")
  )
)
