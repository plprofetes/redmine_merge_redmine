class SourceJournalDetail < ActiveRecord::Base
  include SecondDatabase
  set_table_name :journal_details

  belongs_to :journal, :class_name => 'SourceJournal', :foreign_key => 'journal_id'
  

  def self.migrate
    count = all.count
    x = 0.0
    ctr = 0
    start = Time.now.seconds_since_midnight

    all.each do |source_journal_detail|
      ctr += 1
      x = 100.0*ctr/count
      dt = (Time.now.seconds_since_midnight - start).to_i
      eta = (dt*100/x - dt).to_i
      puts "..[journal_details][#{x.round 4}%][ETA: #{eta/60}m #{eta.modulo 60}s] #{source_journal_detail.id} "

      if source_journal_detail.journal_id.nil? 
        puts ".. [!!] nil journal id: #{source_journal_detail.journal_id}"
        next
      end

      JournalDetail.create!(source_journal_detail.attributes) do |jd|
        njid = RedmineMerge::Mapper.get_new_journal_id(source_journal_detail.journal_id)
        if njid.nil?
          puts "parent journal not in Mapper!"
          next
        end

        jd.journal = Journal.find(njid)

        # Need to remap property keys to their new ids
        if source_journal_detail.prop_key.include?('_id')
          property_name = source_journal_detail.prop_key.to_s.gsub(/\_id$/, "").to_sym
          association = Issue.reflect_on_all_associations.detect {|a| a.name == property_name }
          
          if association
            jd.old_value = RedmineMerge::Mapper.find_id_by_property(association.klass, source_journal_detail.old_value)
            jd.value = RedmineMerge::Mapper.find_id_by_property(association.klass, source_journal_detail.value)
          end
        end
      end      

    end
  end
end
