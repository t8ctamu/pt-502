module MembersHelper
     # Renders a <th> whose label links to the same page sorted by `key`.
     # Clicking the active column toggles asc/desc; existing filters are preserved.
     def sortable_th(label, key)
          current = params[:sort] == key
       descending = current && params[:dir] == "desc"
       next_dir = current && !descending ? "desc" : "asc"
       arrow = current ? (descending ? " ▼" : " ▲") : ""
       aria_sort = current ? (descending ? "descending" : "ascending") : "none"

       tag.th(
         link_to("#{label}#{arrow}",
                 members_path(request.query_parameters.merge(sort: key, dir: next_dir))),
         aria: { sort: aria_sort }
       )
     end
end
