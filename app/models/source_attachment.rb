class SourceAttachment < ActiveRecord::Base
  include SecondDatabase
  set_table_name :attachments

  belongs_to :author, :class_name => 'SourceUser', :foreign_key => 'author_id'

  def self.migrate

    Setting.establish_connection :source_redmine
    s_source = Setting.find_by_name "attachment_max_size"

    Setting.establish_connection :production
    s_prod = Setting.find_by_name "attachment_max_size"

    if s_source.value > s_prod.value
      s_prod.value = s_source.value
      s_prod.save!
      puts ".. increased max attachment size on production database!"
    end

    count = all.count
    x = 0.0
    ctr = 0
    start = Time.now.seconds_since_midnight

    all.each do |source_attachment|
      ctr += 1
      x = 100.0*ctr/count
      dt = (Time.now.seconds_since_midnight - start).to_i
      eta = (dt*100/x - dt).to_i
      puts "..[attachment][#{x.round 4}%][ETA: #{eta/60}m #{eta.modulo 60}s] #{source_attachment.id} "


      Attachment.create!(source_attachment.attributes) do |a|
        a.author = User.find(RedmineMerge::Mapper.get_new_user_id(source_attachment.author.id))
        a.container = case source_attachment.container_type
                      when "Issue"
                        Issue.find RedmineMerge::Mapper.get_new_issue_id(source_attachment.container_id)
                      when "Document"
                        Document.find RedmineMerge::Mapper.get_new_document_id(source_attachment.container_id)
                      when "WikiPage"
                        WikiPage.find RedmineMerge::Mapper.get_new_wiki_page_id(source_attachment.container_id)
                      when "Project"
                        Project.find RedmineMerge::Mapper.get_new_project_id(source_attachment.container_id)
                      when "Version"
                        Version.find RedmineMerge::Mapper.get_new_version_id(source_attachment.container_id)
                      end
      end
    end
  end
end
