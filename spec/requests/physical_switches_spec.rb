describe "Physical Switches API" do
  let(:physical_switch) { FactoryGirl.create(:physical_switch) }

  context "GET /api/physical_switches" do
    it "returns all Physical Switches" do
      physical_switch

      api_basic_authorize('physical_switch_show_list')

      get(api_physical_switches_url)

      expected = {
        "name"      => "physical_switches",
        "resources" => [{"href" => api_physical_switch_url(nil, physical_switch)}]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  context "GET /api/physical_switches/:id" do
    it "returns a single Physical Switch" do
      api_basic_authorize('physical_switch_show')

      get(api_physical_switch_url(nil, physical_switch))

      expected = {
        "name" => physical_switch.name,
        "href" => api_physical_switch_url(nil, physical_switch)
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  describe "Physical Switches refresh action" do
    context "with an invalid id" do
      it "it responds with 404 Not Found" do
        api_basic_authorize(action_identifier(:physical_switches, :refresh, :resource_actions, :post))

        post(api_physical_switch_url(nil, 999_999), :params => gen_request(:refresh))

        expect(response).to have_http_status(:not_found)
      end
    end

    context "without an appropriate role" do
      it "it responds with 403 Forbidden" do
        api_basic_authorize

        post(api_physical_switch_url(nil, physical_switch), :params => gen_request(:refresh))

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "with an appropriate role" do
      it "rejects refresh for an unspecified Physical Switch" do
        api_basic_authorize(action_identifier(:physical_switches, :refresh, :resource_actions, :post))

        post(api_physical_switches_url, :params => gen_request(:refresh, [{"href" => api_physical_switches_url}, {"href" => api_physical_switches_url}]))

        expect_bad_request(/Must specify an id/i)
      end

      it "refresh of a single Physical Switch" do
        api_basic_authorize('physical_switch_refresh')

        post(api_physical_switch_url(nil, physical_switch), :params => gen_request(:refresh))

        expect_single_action_result(:success => true, :message => /#{physical_switch.id}.* refreshing/i, :href => api_physical_switch_url(nil, physical_switch))
      end

      it "refresh of multiple Physical Switches" do
        first_physical_switch = FactoryGirl.create(:physical_switch)
        second_physical_switch = FactoryGirl.create(:physical_switch)
        api_basic_authorize('physical_switch_refresh')

        post(api_physical_switches_url, :params => gen_request(:refresh, [{"href" => api_physical_switch_url(nil, first_physical_switch)}, {"href" => api_physical_switch_url(nil, second_physical_switch)}]))

        expected = {
          "results" => a_collection_containing_exactly(
            a_hash_including(
              "message" => a_string_matching(/#{first_physical_switch.id}.* refreshing/i),
              "success" => true,
              "href"    => api_physical_switch_url(nil, first_physical_switch)
            ),
            a_hash_including(
              "message" => a_string_matching(/#{second_physical_switch.id}.* refreshing/i),
              "success" => true,
              "href"    => api_physical_switch_url(nil, second_physical_switch)
            )
          )
        }
        expect(response.parsed_body).to include(expected)
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "Physical Switches restart action" do
    let(:action) { :restart }

    context "For multiple resources" do
      context "With an invalid id and valid id" do
        it "returns a HTTP status 200, perform the action for the valid resource and fail for the invalid" do
          api_basic_authorize(action_identifier(:physical_switches, action, :resource_actions, :post))

          post(api_physical_switches_url, :params => gen_request(action, [{"href" => api_physical_switch_url(nil, physical_switch)}, {"href" => api_physical_switch_url(nil, 999_999)}]))

          expected = {
            "results" => a_collection_containing_exactly(
              a_hash_including(
                "message" => a_string_matching("Performing #{action} for Physical Switch id:#{physical_switch.id} name: '#{physical_switch.name}'"),
                "success" => true,
                "href"    => api_physical_switch_url(nil, physical_switch)
              ),
              a_hash_including(
                "success" => false
              )
            )
          }
          expect(response.parsed_body).to include(expected)
          expect(response).to have_http_status(:ok)
        end
      end

      context "With a valid request" do
        it "performs the action succesfully" do
          api_basic_authorize(action_identifier(:physical_switches, action, :resource_actions, :post))

          post(api_physical_switches_url, :params => gen_request(action, [{"href" => api_physical_switch_url(nil, physical_switch)}]))

          expected = {
            "results" => a_collection_containing_exactly(
              a_hash_including(
                "message" => a_string_matching("Performing #{action} for Physical Switch id:#{physical_switch.id} name: '#{physical_switch.name}'"),
                "success" => true,
                "href"    => api_physical_switch_url(nil, physical_switch)
              )
            )
          }
          expect(response.parsed_body).to include(expected)
          expect(response).to have_http_status(:ok)
        end
      end
    end

    context "For a single resource" do
      context "With an invalid id and valid id" do
        it "it responds with 404 Not Found" do
          api_basic_authorize(action_identifier(:physical_switches, action, :resource_actions, :post))

          post(api_physical_switch_url(nil, 999_999), :params => gen_request(action))

          expect(response).to have_http_status(:not_found)
        end
      end

      context "With a valid request" do
        it "restarts the Physical Switch" do
          api_basic_authorize(action_identifier(:physical_switches, action, :resource_actions, :post))

          post(api_physical_switch_url(nil, physical_switch), :params => gen_request(action))

          expect_single_action_result(
            :success => true,
            :message => a_string_matching("Performing #{action} for Physical Switch id:#{physical_switch.id} name: '#{physical_switch.name}'"),
            :href    => api_physical_switch_url(nil, physical_switch)
          )
        end
      end
    end
  end
end
