module HQMF2CQL
  # Handles generation of populations for the main document
  class DocumentPopulationHelper < HQMF2::DocumentPopulationHelper
    include HQMF2::Utilities

    def initialize(entry, doc, document, id_generator, reference_ids = {})
      @entry = entry
      @doc = doc
      @document = document
      @id_generator = id_generator
      @reference_ids = reference_ids
    end

    def extract_populations
      @populations_cql_map = extract_populations_cql_map
      @observations = extract_observations
      [@populations_cql_map, @observations]
    end

    # Extracts the measure observations, will return true if one exists
    def extract_observations
      observations = []


      # look for observation data in separate section but create a population for it if it exists
      observation_section = @doc.xpath('/cda:QualityMeasureDocument/cda:component/cda:measureObservationSection',
                                       HQMF2::Document::NAMESPACES)
      debugger
      unless observation_section.empty?
        observation_section.each do |entry|
          observations << entry.at_xpath("*/cda:measureObservationDefinition/cda:value/cda:expression").values.first.match('\"([A-Za-z0-9]+)\"')[1]
        end
      end
      observations
    end

    # Extracts the mappings between actual HQMF populations and their
    # corresponding CQL define statements.
    def extract_populations_cql_map
      populations_cql_map = {}
      @doc.xpath("//cda:populationCriteriaSection/cda:component[@typeCode='COMP']", HQMF2::Document::NAMESPACES).each do |population_def|
        {
          HQMF::PopulationCriteria::IPP => 'initialPopulationCriteria',
          HQMF::PopulationCriteria::DENOM => 'denominatorCriteria',
          HQMF::PopulationCriteria::NUMER => 'numeratorCriteria',
          HQMF::PopulationCriteria::NUMEX => 'numeratorExclusionCriteria',
          HQMF::PopulationCriteria::DENEXCEP => 'denominatorExceptionCriteria',
          HQMF::PopulationCriteria::DENEX => 'denominatorExclusionCriteria',
          HQMF::PopulationCriteria::MSRPOPL => 'measurePopulationCriteria',
          HQMF::PopulationCriteria::MSRPOPLEX => 'measurePopulationExclusionCriteria'
        }.each_pair do |criteria_id, criteria_element_name|
          criteria_def = population_def.at_xpath("cda:#{criteria_element_name}", HQMF2::Document::NAMESPACES)
          if criteria_def
            cql_statement = criteria_def.at_xpath("*/*/cda:id", HQMF2::Document::NAMESPACES).attribute('extension').to_s.match(/"([^"]*)"/)
            if populations_cql_map[criteria_id].nil?
              populations_cql_map[criteria_id] = []
            end
            cql_statement = cql_statement.to_s.delete('\\"')
            unless populations_cql_map[criteria_id].include? cql_statement
              populations_cql_map[criteria_id].push(cql_statement)
            end
          end
        end
      end
      populations_cql_map
    end
  end
end