module ElanDesign
  module Formtastic
    module Autocomplete
      
      protected

      def autocomplete_input(method, options)
        html_options = options.delete(:input_html) || {}
        association = @object.class.reflect_on_association(method)
        if [:has_many, :has_and_belongs_to_many].include?(association.macro)
          #self.label(method, options_for_label(options).merge(:for => "#{@object_name}_#{method}_autocomplete")) +
          autocomplete_existing_entries(method, options) +
          template.content_tag(:fieldset) do
            template.content_tag(:ol) do
              template.content_tag(:li) do
                autocomplete_multi_field(association, options)
              end
            end
          end
        else
          self.label(method, options_for_label(options).merge(:for => "#{@object_name}_#{method}_autocomplete")) +
          autocomplete_single_field(association, options)
        end
      end

      def autocomplete_existing_entries(method, options)
        label = options[:label_method] || detect_label_method(object.send(method))
        value = options[:value_method] || :id
        remove_link = options[:remove_link] || template.image_tag('/images/delete.png', :alt => 'Remove')
        id_stub = "selected_#{@object_name}_#{method}"
        association = @object.class.reflect_on_association(method)
        template.content_tag(:fieldset) do
          template.content_tag(:legend) do
            template.content_tag(:span, :class => :label) do
              method
            end
          end +
          template.content_tag(:ol, :id => id_stub, :class => 'auto_complete_selections') do
            object.send(method).map { |selection|
              template.content_tag(:li, 
                template.hidden_field_tag("#{@object_name}[#{method.to_s.singularize}_ids][]", selection.send(value), :id => nil) + 
                selection.send(label) + 
                template.link_to_function(remove_link, "$('#{id_stub}_#{selection.send(value)}').remove()"), 
                :id => "#{id_stub}_#{selection.send(value)}"
                                  )
            }.join()
          end
        end
      end

      def autocomplete_indicator(method, options)
        indicator = options[:indicator] || '/images/indicator.gif'
        template.image_tag(indicator, :alt => 'Working', :id => "#{@object_name}_#{method}_indicator", :class => 'indicator', :style => 'display: none')
      end

      def autocomplete_single_field(association, options)
        method = association.name
        label = options[:label_method] || detect_label_method(object.send(method).to_a)
        value = options[:value_method] || :id
        current_value = object.send(method).nil? ? '' : object.send(method).send(label)
        input_name = "#{@object_name}_#{generate_association_input_name(method)}"
        template.text_field_tag("q", current_value, :id => "#{@object_name}_#{method}_autocomplete", :autocomplete => 'off') + 
        hidden_field(association.options[:foreign_key]) +
        autocomplete_indicator(method, options) + 
        template.content_tag(:div, "", :id => "#{@object_name}_#{method}_results", :class => 'auto_complete') +
        template.javascript_tag(<<-EOT
  new Ajax.Autocompleter('#{@object_name}_#{method}_autocomplete', '#{@object_name}_#{method}_results', '#{options[:url]}', {
    updateElement: function(li) {
      $('#{input_name}').value = li.id.replace('result_', '');
      $('#{@object_name}_#{method}_autocomplete').value = li.innerHTML;
    },
    method: 'get'#{", 
    indicator: '#{@object_name}_#{method}_indicator'" if options[:indicator]}
  })
EOT
  ) 

      end

      def autocomplete_multi_field(association, options)
        method = association.name
        label = options[:label_method] || detect_label_method(object.send(method))
        value = options[:value_method] || :id
        remove_link = options[:remove_link] || 'Remove'
        template.text_field_tag("q", '', :id => "#{@object_name}_#{method}_autocomplete", :autocomplete => 'off') +
        autocomplete_indicator(method, options) + 
        template.content_tag(:div, "", :id => "#{@object_name}_#{method}_results", :class => 'auto_complete') +
        template.javascript_tag(<<-EOT
  new Ajax.Autocompleter('#{@object_name}_#{method}_autocomplete', '#{@object_name}_#{method}_results', '#{options[:url]}',  {
    updateElement: function(li) {
      item_id = li.id.replace('result_', '');
      li_id = 'selected_#{@object_name}_#{method}_' + item_id;
      if($(li_id) == null) 
      {
        list_id = 'selected_#{@object_name}_#{method}';
        input = new Element('input', {type: 'hidden', name: '#{@object_name}[#{method.to_s.singularize}_ids][]', value: item_id});
        rem = '$(\\\'' + li_id + '\\\').remove(); return false;'
        remove_link = new Element('a', {href: '#', onclick: rem}).update('#{remove_link}');
        item = new Element('li', {id: li_id}).update(input).insert(li.innerHTML).insert(remove_link);
        $(list_id).insert(item);
      }
      else 
      {
        new Effect.Highlight(li_id)
      }
      $('#{@object_name}_#{method}_autocomplete').value = '';
    },
    method: 'get'#{", 
    indicator: '#{@object_name}_#{method}_indicator'"}
  })
  EOT
  ) 
      end
    end
  end
end
