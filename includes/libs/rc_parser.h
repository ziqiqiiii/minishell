#ifndef RC_PARSER_H
# define RC_PARSER_H

typedef enum e_rc_line_type
{
	RC_LINE_EMPTY = 0,
	RC_LINE_PATH,
	RC_LINE_COMMAND
}	t_rc_line_type;

t_rc_line_type	classify_rc_line(const char *line, const char **value_out);

#endif
