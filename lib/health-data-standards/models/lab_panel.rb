class LabPanel < Entry
  embeds_many :results, class_name: "LabResult"
end
