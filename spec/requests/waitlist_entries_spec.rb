require "rails_helper"

RSpec.describe "WaitlistEntries", type: :request do
  let(:user) { create(:user, :verified) }

  def sign_in(u = user)
    post session_path, params: { email_address: u.email_address, password: "securepassword1" }
  end

  describe "POST /waitlist_entries" do
    context "when unauthenticated" do
      it "redirects to sign in" do
        post waitlist_entries_path
        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when authenticated" do
      before { sign_in }

      it "creates a waitlist entry and redirects to root with notice" do
        expect { post waitlist_entries_path }
          .to change(WaitlistEntry, :count).by(1)

        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(response.body).to match(/waitlist/i)
      end

      it "sets the entry status to pending" do
        post waitlist_entries_path
        expect(WaitlistEntry.last.status).to eq("pending")
        expect(WaitlistEntry.last.user).to eq(user)
      end

      it "does not create a duplicate when user is already pending" do
        create(:waitlist_entry, user: user)

        expect { post waitlist_entries_path }
          .not_to change(WaitlistEntry, :count)

        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(response.body).to match(/already on the waitlist/i)
      end

      it "re-activates a notified entry instead of creating a new one" do
        entry = create(:waitlist_entry, :notified, user: user)

        expect { post waitlist_entries_path }
          .not_to change(WaitlistEntry, :count)

        expect(entry.reload.status).to eq("pending")
        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(response.body).to match(/added back to the waitlist/i)
      end
    end
  end

  describe "DELETE /waitlist_entries/:id" do
    context "when unauthenticated" do
      it "redirects to sign in" do
        entry = create(:waitlist_entry, user: user)
        delete waitlist_entry_path(entry)
        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when authenticated" do
      before { sign_in }

      it "destroys the entry and redirects to root" do
        entry = create(:waitlist_entry, user: user)

        expect { delete waitlist_entry_path(entry) }
          .to change(WaitlistEntry, :count).by(-1)

        expect(response).to redirect_to(root_path)
      end

      it "does not destroy another user's entry" do
        other_user  = create(:user)
        other_entry = create(:waitlist_entry, user: other_user)

        expect { delete waitlist_entry_path(other_entry) }
          .not_to change(WaitlistEntry, :count)
      end
    end
  end
end
