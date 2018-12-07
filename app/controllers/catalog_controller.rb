# -*- encoding : utf-8 -*-
require 'blacklight/catalog'

class CatalogController < ApplicationController

  include Hydra::Catalog

  # These before_filters apply the hydra access controls
  #before_filter :enforce_show_permissions, :only=>:show
  # This applies appropriate access controls to all solr queries
  Hydra::SearchBuilder.default_processor_chain -= [:add_access_controls_to_solr_params]
  # TODO feedback button
  # TODO search history as a tree
  # TODO named entities + integrate thesis method using solr spellcheck ?
  # TODO add image part in "see extracts"
  # TODO handle hyphenated words (information already in alto, to be checked)
  # TODO add position to hl : https://issues.apache.org/jira/browse/SOLR-4722
  # TODO configure stopwords etc for solr
  configure_blacklight do |config|
    config.view.gallery.partials = [:index_header, :index]
    config.view.masonry.partials = [:index]
    config.view.slideshow.partials = [:index]


    config.show.tile_source_field = :content_metadata_image_iiif_info_ssm
    config.show.partials.insert(1, :openseadragon)

    # config.index.thumbnail_method= :render_thumbnail # see helpers
    config.index.thumbnail_field = :thumbnail_url_ss

    ## Class for sending and receiving requests from a search index
    # config.repository_class = Blacklight::Solr::Repository
    #
    ## Class for converting Blacklight's url parameters to into request parameters for the search index
    # config.search_builder_class = ::SearchBuilder
    #
    ## Model that maps search index responses to the blacklight response model
    # config.response_model = Blacklight::Solr::Response

    ## Default parameters to send to solr for all search-like requests. See also SearchBuilder#processed_parameters
    config.default_solr_params = {
      qf: 'all_text_ten_siv all_text_tfr_siv all_text_tde_siv all_text_tfi_siv all_text_tse_siv',
      # hl: 'on',
      # 'hl.method': 'unified',
      # 'hl.fl': 'all_text_*',
      # 'hl.snippets': 10,
      # 'hl.fragsize': 200,
      # 'hl.simple.pre': '<span style="background-color: red; color: white;">',
      # 'hl.simple.post': '</span>',
      # 'f.all_text_ten_si.hl.useFastVectorHighlighter': true,
      # 'f.all_text_tfr_si.hl.simple.pre': '<span style="background-color: red; color: white;">',
      # 'f.all_text_tfr_si.hl.simple.post': '</span>',
      # 'f.all_text_tfr_si.hl.useFastVectorHighlighter': true,
      # 'f.all_text_tde_si.hl.simple.pre': '<span style="background-color: red; color: white;">',
      # 'f.all_text_tde_si.hl.simple.post': '</span>',
      # 'f.all_text_tde_si.hl.useFastVectorHighlighter': true,
      # 'f.all_text_tfi_si.hl.simple.pre': '<span style="background-color: red; color: white;">',
      # 'f.all_text_tfi_si.hl.simple.post': '</span>',
      # 'f.all_text_tfi_si.hl.useFastVectorHighlighter': true,
      # 'f.all_text_tse_si.hl.simple.pre': '<span style="background-color: red; color: white;">',
      # 'f.all_text_tse_si.hl.simple.post': '</span>',
      # 'f.all_text_tse_si.hl.useFastVectorHighlighter': true,
      qt: 'search',
      rows: 10
    }

    # solr field configuration for search results/index views
    config.index.title_field = 'title_ssi'
    config.index.display_type_field = 'has_model_ssim'


    # solr fields that will be treated as facets by the blacklight application
    #   The ordering of the field names is the order of the display
    #
    # Setting a limit will trigger Blacklight's 'more' facet values link.
    # * If left unset, then all facet values returned by solr will be displayed.
    # * If set to an integer, then "f.somefield.facet.limit" will be added to
    # solr request, with actual solr request being +1 your configured limit --
    # you configure the number of items you actually want _tsimed_ in a page.
    # * If set to 'true', then no additional parameters will be sent to solr,
    # but any 'sniffed' request limit parameters will be used for paging, with
    # paging at requested limit -1. Can sniff from facet.limit or
    # f.specific_field.facet.limit solr request params. This 'true' config
    # can be used if you set limits in :default_solr_params, or as defaults
    # on the solr side in the request handler itself. Request handler defaults
    # sniffing requires solr requests to be made with "echoParams=all", for
    # app code to actually have it echo'd back to see it.
    #
    # :show may be set to false if you don't want the facet to be drawn in the
    # facet bar
    # config.add_facet_field solr_name('object_type', :facetable), label: 'Format'
    # config.add_facet_field solr_name('pub_date', :facetable), label: 'Publication Year'
    # config.add_facet_field solr_name('subject_topic', :facetable), label: 'Topic', limit: 20
    # config.add_facet_field solr_name('lc1_letter', :facetable), label: 'Call Number'
    # config.add_facet_field solr_name('subject_geo', :facetable), label: 'Region'
    # config.add_facet_field solr_name('subject_era', :facetable), label: 'Era'
    config.add_facet_field solr_name('language', :string_searchable_uniq), helper_method: :convert_language_to_locale, limit: true
    config.add_facet_field solr_name('date_created', :date_searchable_uniq), helper_method: :convert_date_to_locale_facet, label: 'Date', date: true
    config.add_facet_field 'member_of_collection_ids_ssim', helper_method: :get_collection_title_from_id, label: 'Newspaper'

    # Have BL send all facet field names to Solr, which has been the default
    # previously. Simply remove these lines if you'd rather use Solr request
    # handler defaults, or have no facets.
    config.default_solr_params[:'facet.field'] = config.facet_fields.keys
    #use this instead if you don't want to query facets marked :show=>false
    #config.default_solr_params[:'facet.field'] = config.facet_fields.select{ |k, v| v[:show] != false}.keys


    # solr fields to be displayed in the index (search results) view
    #   The ordering of the field names is the order of the display

    config.add_index_field solr_name('title', :string_searchable_uniq), label: 'Title'
    config.add_index_field solr_name('date_created', :date_searchable_uniq), helper_method: :convert_date_to_locale, label: 'Published date'
    config.add_index_field solr_name('publisher', :text_en_searchable_uniq), label: 'Publisher'
    config.add_index_field solr_name('nb_pages', :int_searchable), label: 'Number of pages'

    # config.add_index_field solr_name('title', :stored_searchable, type: :string), label: 'Title'
    # config.add_index_field solr_name('title_vern', :stored_searchable, type: :string), label: 'Title'
    # config.add_index_field solr_name('author', :stored_searchable, type: :string), label: 'Author'
    # config.add_index_field solr_name('author_vern', :stored_searchable, type: :string), label: 'Author'
    # config.add_index_field solr_name('format', :symbol), label: 'Format'
    # config.add_index_field solr_name('language', :stored_searchable, type: :string), label: 'Language'
    # config.add_index_field solr_name('published', :stored_searchable, type: :string), label: 'Published'
    # config.add_index_field solr_name('published_vern', :stored_searchable, type: :string), label: 'Published'
    # config.add_index_field solr_name('lc_callnum', :stored_searchable, type: :string), label: 'Call number'

    #config.add_index_field solr_name('text_content', :stored_searchable, type: :string), label: 'OCR text'

    # solr fields to be displayed in the show (single result) view
    #   The ordering of the field names is the order of the display
    # config.add_show_field solr_name('title', :stored_searchable, type: :string), label: 'Title'
    # config.add_show_field solr_name('title_vern', :stored_searchable, type: :string), label: 'Title'
    # config.add_show_field solr_name('subtitle', :stored_searchable, type: :string), label: 'Subtitle'
    # config.add_show_field solr_name('subtitle_vern', :stored_searchable, type: :string), label: 'Subtitle'
    # config.add_show_field solr_name('author', :stored_searchable, type: :string), label: 'Author'
    # config.add_show_field solr_name('author_vern', :stored_searchable, type: :string), label: 'Author'
    # config.add_show_field solr_name('format', :symbol), label: 'Format'
    # config.add_show_field solr_name('url_fulltext_tsim', :stored_searchable, type: :string), label: 'URL'
    # config.add_show_field solr_name('url_suppl_tsim', :stored_searchable, type: :string), label: 'More Information'
    # config.add_show_field solr_name('language', :stored_searchable, type: :string), label: 'Language'
    # config.add_show_field solr_name('published', :stored_searchable, type: :string), label: 'Published'
    # config.add_show_field solr_name('published_vern', :stored_searchable, type: :string), label: 'Published'
    # config.add_show_field solr_name('lc_callnum', :stored_searchable, type: :string), label: 'Call number'
    # config.add_show_field solr_name('isbn', :stored_searchable, type: :string), label: 'ISBN'

    config.add_show_field solr_name('original_uri', :string_stored_uniq), label: 'Original URI'
    config.add_show_field solr_name('publisher', :string_searchable_uniq), label: 'Publisher'
    config.add_show_field solr_name('date_created', :date_searchable_uniq), helper_method: :convert_date_to_locale, label: 'Date created'
    config.add_show_field solr_name('nb_pages', :int_searchable), label: 'Number of pages'

    # "fielded" search configuration. Used by pulldown among other places.
    # For supported keys in hash, see rdoc for Blacklight::SearchFields
    #
    # Search fields will inherit the :qt solr request handler from
    # config[:default_solr_parameters], OR can specify a different one
    # with a :qt key/value. Below examples inherit, except for subject
    # that specifies the same :qt as default for our own internal
    # testing purposes.
    #
    # The :key is what will be used to identify this BL search field internally,
    # as well as in URLs -- so changing it after deployment may break bookmarked
    # urls.  A display label will be automatically calculated from the :key,
    # or can be specified manually to be different.

    # This one uses all the defaults set by the solr request handler. Which
    # solr request handler? The one set in config[:default_solr_parameters][:qt],
    # since we aren't specifying it otherwise.

    config.add_search_field 'all_fields', label: 'All Fields'


    # Now we see how to over-ride Solr request handler defaults, in this
    # case for a BL "search field", which is really a dismax aggregate
    # of Solr search fields.

    # config.add_search_field('title') do |field|
    #   # :solr_local_parameters will be sent using Solr LocalParams
    #   # syntax, as eg {! qf=$title_qf }. This is neccesary to use
    #   # Solr parameter de-referencing like $title_qf.
    #   # See: http://wiki.apache.org/solr/LocalParams
    #   field.solr_local_parameters = {
    #     qf: '$title_qf',
    #     pf: '$title_pf'
    #   }
    # end
    #
    # config.add_search_field('author') do |field|
    #   field.solr_local_parameters = {
    #     qf: '$author_qf',
    #     pf: '$author_pf'
    #   }
    # end
    #
    # # Specifying a :qt only to show it's possible, and so our internal automated
    # # tests can test it. In this case it's the same as
    # # config[:default_solr_parameters][:qt], so isn't actually neccesary.
    # config.add_search_field('subject') do |field|
    #   field.qt = 'search'
    #   field.solr_local_parameters = {
    #     qf: '$subject_qf',
    #     pf: '$subject_pf'
    #   }
    # end

    # "sort results by" select (pulldown)
    # label in pulldown is followed by the name of the SOLR field to sort by and
    # whether the sort is ascending or descending (it must be asc or desc
    # except in the relevancy case).
    config.add_sort_field 'score desc, date_created_dtsi desc', label: 'relevance'
    # config.add_sort_field 'pub_date_dtsi desc', label: 'year'
    # config.add_sort_field 'author_tesi asc', label: 'author'
    # config.add_sort_field 'title_tesi asc', label: 'title'

    # If there are more than this many search results, no spelling ("did you
    # mean") suggestion is offered.
    config.spell_max = 5
  end

  def index
    (@response, @document_list) = search_results(params)
    pp @response[:highlighting]
    respond_to do |format|
      format.html { store_preferred_view }
      format.rss  { render :layout => false }
      format.atom { render :layout => false }
      format.json do
        @presenter = Blacklight::JsonPresenter.new(@response,
                                                   @document_list,
                                                   facets_from_request,
                                                   blacklight_config)
      end
      additional_response_formats(format)
      document_export_formats(format)
    end

  end

  def explore
    puts 'ok'
  end

  # this method allow you to change url parameters like utf8 or locale
  def search_action_url options = {}
    url_for(options.reverse_merge(action: 'index'))
  end

end
