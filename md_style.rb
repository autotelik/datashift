all

# https://github.com/mivok/markdownlint/blob/master/docs/RULES.md#md013---line-length
# We exclude this rule because we believe it is easier to maintain the content
# if there is no limit on line lengths. Most editors can wrap the text and
# GitHub renders the content without issue. If we enforced a limit it would mean
# when editing a paragraph contributors would not only need to edit the content,
# but then also reformat it. We feel this last step is unnecessary.
exclude_rule 'MD002'
exclude_rule 'MD009'
exclude_rule 'MD013'
