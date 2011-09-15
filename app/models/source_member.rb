class SourceMember < ActiveRecord::Base
  include SecondDatabase
    set_table_name :members

#      belongs_to :user, :class_name => 'SourceUser', :foreign_key => 'user_id'
#      belongs_to :principal, :class_name => 'SourceUser', :foreign_key => 'user_id' 
#      belongs_to :project, :class_name => 'SourceProject', :foreign_key => 'project_id'  
#      has_many :role, :class_name => 'SourceRole', :join_table => :member_roles, :association_foreign_key => :role_id

        def self.migrate
             Group.establish_connection :source_redmine            
             User.establish_connection :source_redmine
             Project.establish_connection :source_redmine
             Role.establish_connection :source_redmine
             MemberRole.establish_connection :source_redmine
             Member.establish_connection :source_redmine
             groups_old=Group.all
             users_old=User.all
             projects=Project.all
             roles=Role.all
             member=Member.all
             member_roles=MemberRole.all             
             hash_member={}
             hash_member_group={}             
             puts "!!!!!!!!!!!!!!! Members Migration !!!!!!!!!!!!!!!"
             member.each { |m|
                if !(Project.find_by_id(m.project_id).nil?)
                  if !(User.find_by_id(m.user_id).nil?)
                    hash_mr={}
                    # puts "User login  " << User.find_by_id(m.user_id).login
                    hash_mr[:user]=User.find_by_id(m.user_id).login
                    hash_mr[:project]=Project.find_by_id(m.project_id).name
                    hash_mr[:details]=m
                    hash_mr[:role]=Role.find_by_id(MemberRole.find_by_member_id(m.id).role_id).name
                    hash_member[m.id]=hash_mr
                  elsif !(Group.find_by_id(m.user_id).nil?)
                    hash_mr={} 
                    # puts "Group name  " << Group.find_by_id(m.user_id).lastname
                    hash_mr[:group]=Group.find_by_id(m.user_id).lastname
                    hash_mr[:project]=Project.find_by_id(m.project_id).name
                    hash_mr[:details]=m
                    hash_mr[:role]=Role.find_by_id(MemberRole.find_by_member_id(m.id).role_id).name
                    hash_member_group[m.id]=hash_mr
                  end
                end
             }
               
             Group.establish_connection :production
             User.establish_connection :production             
             Project.establish_connection :production
             Role.establish_connection :production                  
             MemberRole.establish_connection :production
             Member.establish_connection :production
             hash_member.each do |k,m_id|
                    puts "..Creating for  " << m_id[:user]
                        #puts User.find_by_login(m_id[:user]).login
                        u_id = User.find_by_login(m_id[:user]).id                       
                        p_id = Project.find_by_name(m_id[:project]).id
                        creation = m_id[:details].created_on
                        mail = m_id[:details].mail_notification
                        role = Role.find_by_name(m_id[:role])                       
                        # puts "Rola " << m_id[:role]
                        if !(User.find_by_login(m_id[:user]).nil?)
                          m=Member.create(:user_id => u_id, :project_id => p_id, :created_on => creation, :mail_notification => :mail)
                          m.roles << role
                          m.save!
                        end
                        #MemberRole.create!(:member_id => m.id, :role_id => role_id)
                        
                            #next unless Member.find_by_name(source_member.name).nil?
                            #      m=Member.create!(source_member.attributes)
                            #      old_user_id=m.user_id
                            #      m.user_id=
                            #end
             end

             hash_member_group.each do |k, m_id|

                u_id = Group.find_by_login(m_id[:group]).id                       
                p_id = Project.find_by_name(m_id[:project]).id
                creation = m_id[:details].created_on
                mail = m_id[:details].mail_notification
                role = Role.find_by_name(m_id[:role])                       
                #puts "Rola " << m_id[:role]
                if !(Group.find_by_login(m_id[:group]).nil?)
                  m=Member.create(:user_id => u_id, :project_id => p_id, :created_on => creation, :mail_notification => :mail)
                  m.roles << role
                  m.save!
                end             
        end
   end         
end
