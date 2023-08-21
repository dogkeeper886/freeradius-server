/*
 *   This library is free software; you can redistribute it and/or
 *   modify it under the terms of the GNU Lesser General Public
 *   License as published by the Free Software Foundation; either
 *   version 2.1 of the License, or (at your option) any later version.
 *
 *   This library is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 *   Lesser General Public License for more details.
 *
 *   You should have received a copy of the GNU Lesser General Public
 *   License along with this library; if not, write to the Free Software
 *   Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301, USA
 */

/** Pair serialisation API
 *
 * @file src/lib/util/pair_print.c
 *
 * @copyright 2020 The FreeRADIUS server project
 */
#include <freeradius-devel/util/pair.h>
#include <freeradius-devel/util/talloc.h>
#include <freeradius-devel/util/proto.h>
#include <freeradius-devel/util/pair_legacy.h>

/** Print the value of an attribute to a string
 *
 * @param[in] out	Where to write the string.
 * @param[in] vp	to print.
 * @param[in] quote	Char to add before and after printed value,
 *			if 0 no char will be added, if < 0 raw string
 *			will be added.
 * @return
 *	- >= 0 length of data written to out.
 *	- <0 the number of bytes we would have needed to write
 *	  the complete string to out.
 */
ssize_t fr_pair_print_value_quoted(fr_sbuff_t *out, fr_pair_t const *vp, fr_token_t quote)
{
	fr_sbuff_t	our_out;

	PAIR_VERIFY(vp);

	switch (vp->vp_type) {
	/*
	 *	For structural types descend down
	 */
	case FR_TYPE_STRUCTURAL:
		our_out = FR_SBUFF(out);
		FR_SBUFF_IN_CHAR_RETURN(&our_out, '{', ' ');

		FR_SBUFF_RETURN(fr_pair_list_print, &our_out, vp->da, &vp->vp_group);

		FR_SBUFF_IN_CHAR_RETURN(&our_out, ' ', '}');

		FR_SBUFF_SET_RETURN(out, &our_out);

	/*
	 *	For simple types just print the box
	 */
	default:
		return fr_value_box_print_quoted(out, &vp->data, quote);
	}
}

/** Print one attribute and value to a string
 *
 * Print a fr_pair_t in the format:
@verbatim
	<attribute_name> <op> <value>
@endverbatim
 * to a string.
 *
 * @param[in] out	Where to write the string.
 * @param[in] parent	If not NULL, only print OID components from
 *			this parent to the VP.
 * @param[in] vp	to print.
 * @return
 *	- Length of data written to out.
 *	- value >= outlen on truncation.
 */
ssize_t fr_pair_print(fr_sbuff_t *out, fr_dict_attr_t const *parent, fr_pair_t const *vp)
{
	char const		*token = NULL;
	fr_sbuff_t		our_out = FR_SBUFF(out);

	PAIR_VERIFY(vp);

	if ((vp->op > T_INVALID) && (vp->op < T_TOKEN_LAST)) {
		token = fr_tokens[vp->op];
	} else {
		token = "<INVALID-TOKEN>";
	}

	/*
	 *	Groups are printed from the root.
	 */
	if (parent && (parent->type == FR_TYPE_GROUP)) parent = NULL;

	if (vp->da->flags.is_raw) FR_SBUFF_IN_STRCPY_LITERAL_RETURN(&our_out, "raw.");
	FR_DICT_ATTR_OID_PRINT_RETURN(&our_out, parent, vp->da, false);
	FR_SBUFF_IN_CHAR_RETURN(&our_out, ' ');
	FR_SBUFF_IN_STRCPY_RETURN(&our_out, token);
	FR_SBUFF_IN_CHAR_RETURN(&our_out, ' ');
	FR_SBUFF_RETURN(fr_pair_print_value_quoted, &our_out, vp, T_DOUBLE_QUOTED_STRING);

	FR_SBUFF_SET_RETURN(out, &our_out);
}

/** Print one attribute and value to a string with escape rules
 *
 *  Similar to fr_pair_print(), but secrets are omitted.  This function duplicates parts of the functionality
 *  of fr_pair_print(). fr_pair_print_value_quoted(), and fr_value_box_print_quoted(), but for the special
 *  case of secure strings.
 *
 *  Note that only secrets of type "string" and "octets" are omitted.  Other "secret" data types are still
 *  printed as-is.
 *
 *  "octets" are still printed as "<<< secret >>>".  Which won't parse correctly, but that's fine.  Because
 *  omitted data is not meant to be parsed into real data.
 *
 * @param[in] out	Where to write the string.
 * @param[in] parent	If not NULL, only print OID components from
 *			this parent to the VP.
 * @param[in] vp	to print.

 * @return
 *	- < 0 on error
 *	- Length of data written to out.
 *	- value >= outlen on truncation.
 */
ssize_t fr_pair_print_secure(fr_sbuff_t *out, fr_dict_attr_t const *parent, fr_pair_t const *vp)
{
	char const		*token = NULL;
	fr_sbuff_t		our_out = FR_SBUFF(out);

	PAIR_VERIFY(vp);

	if ((vp->op > T_INVALID) && (vp->op < T_TOKEN_LAST)) {
		token = fr_tokens[vp->op];
	} else {
		token = "<INVALID-TOKEN>";
	}

	/*
	 *	Groups are printed from the root.
	 */
	if (parent && (parent->type == FR_TYPE_GROUP)) parent = NULL;

	if (vp->da->flags.is_raw) FR_SBUFF_IN_STRCPY_LITERAL_RETURN(&our_out, "raw.");
	FR_DICT_ATTR_OID_PRINT_RETURN(&our_out, parent, vp->da, false);
	FR_SBUFF_IN_CHAR_RETURN(&our_out, ' ');
	FR_SBUFF_IN_STRCPY_RETURN(&our_out, token);
	FR_SBUFF_IN_CHAR_RETURN(&our_out, ' ');

	if (fr_type_is_leaf(vp->vp_type)) {
		switch (vp->vp_type) {
		case FR_TYPE_STRING:
			if (vp->data.secret) goto secret;
			FALL_THROUGH;

		case FR_TYPE_DATE:
			FR_SBUFF_IN_CHAR_RETURN(&our_out, '"');
			FR_SBUFF_RETURN(fr_value_box_print, &our_out, &vp->data, &fr_value_escape_double);
			FR_SBUFF_IN_CHAR_RETURN(&our_out, '"');
			break;

		case FR_TYPE_OCTETS:
			if (vp->data.secret) {
			secret:
				FR_SBUFF_IN_STRCPY_LITERAL_RETURN(&our_out, "<<< secret >>>");
				break;
			}
			FALL_THROUGH;

		default:
			if (fr_value_box_print(&our_out, &vp->data, NULL) < 0) return -1;
			break;
		}
	} else {
		fr_pair_t *child;
		fr_dcursor_t cursor;

		FR_SBUFF_IN_CHAR_RETURN(&our_out, '{', ' ');
		for (child = fr_pair_dcursor_init(&cursor, &vp->vp_group);
		     child != NULL;
		     child = fr_dcursor_next(&cursor)) {
			FR_SBUFF_RETURN(fr_pair_print_secure, &our_out, vp->da, child);
			if (fr_dcursor_next_peek(&cursor)) FR_SBUFF_IN_CHAR_RETURN(&our_out, ',', ' ');
		}
		FR_SBUFF_IN_CHAR_RETURN(&our_out, ' ', '}');
	}

	FR_SBUFF_SET_RETURN(out, &our_out);
}

static ssize_t fr_pair_list_print_unflatten(fr_sbuff_t *out, fr_dict_attr_t const *parent, fr_pair_list_t const *list, fr_pair_t **vp_p)
{
	bool		comma = false;
	fr_pair_t	*vp = *vp_p;
	fr_pair_t	*next = fr_pair_list_next(list, vp);
	fr_da_stack_t	da_stack;
	fr_sbuff_t	our_out = FR_SBUFF(out);

	fr_proto_da_stack_build(&da_stack, vp->da);

	fr_assert(fr_type_is_structural(parent->type) || fr_dict_attr_is_key_field(parent));

redo:
	/*
	 *	Not yet at the correct parent.  Print out the wrapper, and keep looping while the parent is the same.
	 */
	if (fr_type_is_leaf(vp->vp_type) && (da_stack.da[parent->depth - 1] == parent) && (vp->da->parent != parent)) {
		if (comma) FR_SBUFF_IN_STRCPY_LITERAL_RETURN(&our_out, ", ");

		fr_assert(da_stack.da[parent->depth] != NULL);

		FR_SBUFF_IN_STRCPY_RETURN(&our_out, da_stack.da[parent->depth]->name);
		FR_SBUFF_IN_STRCPY_LITERAL_RETURN(&our_out, " = { ");

		while (true) {
			fr_pair_t *prev = vp;

			FR_SBUFF_RETURN(fr_pair_list_print_unflatten, &our_out, da_stack.da[parent->depth], list, &vp);

			if (!vp) break;

			if (vp->da->depth <= parent->depth) break;

			/*
			 *	Flat structures are listed in order.  Which means as soon as we go from 1..N back to
			 *	1, we have ended the current structure.
			 */
			if ((prev->da->parent->type == FR_TYPE_STRUCT) &&
			    (vp->da->parent == prev->da->parent) &&
			    (vp->da->attr < prev->da->attr)) {
				break;
			}

			/*
			 *	We have different parents, stop printing.
			 */
			fr_proto_da_stack_build(&da_stack, vp->da);

			if (da_stack.da[parent->depth - 1] != parent) break;
		}

		/*
		 *	We've either hit the end of the list, OR a VP which has a different parent, OR the end
		 *	of this struct.
		 */
		FR_SBUFF_IN_STRCPY_LITERAL_RETURN(&our_out, " }");

		if (vp) {
			next = fr_pair_list_next(list, vp);
			if (next) comma = true;
		} else {
			next = NULL;
		}

		*vp_p = next;

		if (!next) {
			FR_SBUFF_SET_RETURN(out, &our_out);
		}

		vp = next;
	}

	/*
	 *	Print out things which are at the root.
	 */
	while (vp->da->parent->flags.is_root) {
		if (comma) FR_SBUFF_IN_STRCPY_LITERAL_RETURN(&our_out, ", ");

		FR_SBUFF_RETURN(fr_pair_print, &our_out, vp->da->parent, vp);
		next = fr_pair_list_next(list, vp);
		if (!next) goto done;

		comma = true;
		vp = next;
	}

	/*
	 *	Allow nested attributes to be mixed with flat attributes.
	 */
	while (fr_type_is_structural(vp->vp_type) && (vp->da == parent)) {
		if (comma) FR_SBUFF_IN_STRCPY_LITERAL_RETURN(&our_out, ", ");

		FR_SBUFF_RETURN(fr_pair_print, &our_out, vp->da->parent, vp);
		next = fr_pair_list_next(list, vp);
		if (!next) goto done;

		comma = true;
		vp = next;
	}

	fr_assert(vp->da->parent == parent);

	/*
	 *	Finally loop over the correct children.
	 */
	while (vp->da->parent == parent) {
		if (comma) FR_SBUFF_IN_STRCPY_LITERAL_RETURN(&our_out, ", ");

		FR_SBUFF_RETURN(fr_pair_print, &our_out, vp->da->parent, vp);
		next = fr_pair_list_next(list, vp);
		if (!next) goto done;

		comma = true;
		vp = next;
	}

	/*
	 *	We've printed out all of the VPs at the current depth.  But maybe the next VP is at a
	 *	different depth.  If so, jump back and keep going.
	 */
	if (next) {
		fr_proto_da_stack_build(&da_stack, next->da);
		if (da_stack.da[parent->depth - 1] == parent) {
			vp = next;
			goto redo;
		}
	}

done:
	*vp_p = next;

	FR_SBUFF_SET_RETURN(out, &our_out);
}

/** Print a pair list
 *
 * @param[in] out	Where to write the string.
 * @param[in] parent	parent da to start from
 * @param[in] list	pair list
 * @return
 *	- Length of data written to out.
 *	- value >= outlen on truncation.
 */
ssize_t fr_pair_list_print(fr_sbuff_t *out, fr_dict_attr_t const *parent, fr_pair_list_t const *list)
{
	fr_pair_t	*vp;
	fr_sbuff_t	our_out = FR_SBUFF(out);

	vp = fr_pair_list_head(list);
	if (!vp) {
		FR_SBUFF_IN_CHAR_RETURN(out, '\0');
		return fr_sbuff_used(out);
	}

	/*
	 *	Groups are printed from the root.
	 */
	if (parent && (parent->type == FR_TYPE_GROUP)) parent = NULL;

	while (true) {
		unsigned int depth;
		fr_da_stack_t da_stack;

		fr_proto_da_stack_build(&da_stack, vp->da);

		if (!fr_pair_legacy_print_nested ||
		    (!parent && (vp->da->depth == 1)) ||
		    (vp->da->parent == parent) ||
		    (parent && (fr_dict_by_da(parent) != fr_dict_by_da(vp->da))) ||
		    (parent && (da_stack.da[parent->depth] == parent) && (parent->depth + 1 == vp->da->depth))) {
			FR_SBUFF_RETURN(fr_pair_print, &our_out, parent, vp);
			vp = fr_pair_list_next(list, vp);
		} else {
			/*
			 *      We have to print a partial tree, starting from the root.
			 */
                      if (!parent) {
                              depth = 1;
                      } else {
                              depth = parent->depth + 1;
                      }

		      /*
		       *	Wrap the children.
		       */
		      FR_SBUFF_IN_STRCPY_RETURN(&our_out, da_stack.da[depth - 1]->name);
		      FR_SBUFF_IN_STRCPY_LITERAL_RETURN(&our_out, " = { ");

		      FR_SBUFF_RETURN(fr_pair_list_print_unflatten, &our_out, da_stack.da[depth - 1], list, &vp);
		      FR_SBUFF_IN_STRCPY_LITERAL_RETURN(&our_out, " }");
		}

		if (!vp) break;

		FR_SBUFF_IN_STRCPY_LITERAL_RETURN(&our_out, ", ");
	}

	FR_SBUFF_SET_RETURN(out, &our_out);
}

/** Print one attribute and value to FP
 *
 * Complete string with '\\t' and '\\n' is written to buffer before printing to
 * avoid issues when running with multiple threads.
 *
 * This function will print *flattened* lists, as is suitable for use
 * with rlm_detail.  In fact, the only user of this function is
 * rlm_detail.
 *
 * @param fp to output to.
 * @param vp to print.
 */
void fr_pair_fprint(FILE *fp, fr_pair_t const *vp)
{
	char		buff[1024];
	fr_sbuff_t	sbuff = FR_SBUFF_OUT(buff, sizeof(buff));

	PAIR_VERIFY(vp);

	(void) fr_sbuff_in_char(&sbuff, '\t');
	(void) fr_pair_print(&sbuff, NULL, vp);
	(void) fr_sbuff_in_char(&sbuff, '\n');

	fputs(buff, fp);
}


static void fr_pair_list_log_sbuff(fr_log_t const *log, int lvl, fr_pair_t *parent, fr_pair_list_t const *list, char const *file, int line, fr_sbuff_t *sbuff)
{
	fr_dict_attr_t const *parent_da = NULL;

	fr_pair_list_foreach(list, vp) {
		PAIR_VERIFY_WITH_LIST(list, vp);

		fr_sbuff_set_to_start(sbuff);

		if (vp->da->flags.is_raw) (void) fr_sbuff_in_strcpy(sbuff, "raw.");

		if (parent && (parent->vp_type != FR_TYPE_GROUP)) parent_da = parent->da;
		if (fr_dict_attr_oid_print(sbuff, parent_da, vp->da, false) <= 0) return;

		/*
		 *	Recursively print grouped attributes.
		 */
		switch (vp->vp_type) {
		case FR_TYPE_STRUCTURAL:
			fr_log(log, L_DBG, file, line, "%*s%*s {", lvl * 2, "",
			       (int) fr_sbuff_used(sbuff), fr_sbuff_start(sbuff));
			_fr_pair_list_log(log, lvl + 1, vp, &vp->vp_group, file, line);
			fr_log(log, L_DBG, file, line, "%*s}", lvl * 2, "");
			break;

		default:
			(void) fr_sbuff_in_strcpy(sbuff, " = ");
			fr_value_box_print_quoted(sbuff, &vp->data, T_DOUBLE_QUOTED_STRING);

			fr_log(log, L_DBG, file, line, "%*s%*s", lvl * 2, "",
			       (int) fr_sbuff_used(sbuff), fr_sbuff_start(sbuff));
		}
	}
}


/** Print a list of attributes and enumv
 *
 * @param[in] log	to output to.
 * @param[in] lvl	depth in structural attribute.
 * @param[in] parent	parent attribute
 * @param[in] list	to print.
 * @param[in] file	where the message originated
 * @param[in] line	where the message originated
 */
void _fr_pair_list_log(fr_log_t const *log, int lvl, fr_pair_t *parent, fr_pair_list_t const *list, char const *file, int line)
{
	fr_sbuff_t sbuff;
	char buffer[1024];

	fr_sbuff_init_out(&sbuff, buffer, sizeof(buffer));

	fr_pair_list_log_sbuff(log, lvl, parent, list, file, line, &sbuff);
}

/** Dumps a list to the default logging destination - Useful for calling from debuggers
 *
 */
void fr_pair_list_debug(fr_pair_list_t const *list)
{
	_fr_pair_list_log(&default_log, 0, NULL, list, "<internal>", 0);
}


/** Dumps a pair to the default logging destination - Useful for calling from debuggers
 *
 */
void fr_pair_debug(fr_pair_t const *pair)
{
	fr_sbuff_t sbuff;
	char buffer[1024];

	fr_sbuff_init_out(&sbuff, buffer, sizeof(buffer));

	(void) fr_pair_print(&sbuff, NULL, pair);

	fr_log(&default_log, L_DBG, __FILE__, __LINE__, "%pV",
	       fr_box_strvalue_len(fr_sbuff_start(&sbuff), fr_sbuff_used(&sbuff)));
}
