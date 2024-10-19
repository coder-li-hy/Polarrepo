/*-------------------------------------------------------------------------
 *
 * polar_xlog_idx.c
 *   Implementation of parse xlog records.
 *
 * Portions Copyright (c) 1996-2018, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 * Portions Copyright (c) 2021, Alibaba Group Holding limited
 *
 * IDENTIFICATION
 *   src/backend/access/logindex/polar_xlog_idx.c
 *
 *-------------------------------------------------------------------------
 */
#include "postgres.h"

#include "access/bufmask.h"
#include "access/polar_fullpage.h"
#include "access/polar_logindex_redo.h"
#include "catalog/pg_control.h"
#include "miscadmin.h"
#include "storage/buf_internals.h"

static XLogRedoAction
xlog_idx_fpi_redo(XLogReaderState *record, BufferTag *tag, Buffer *buffer)
{
	XLogRedoAction action = BLK_NOTFOUND;
	uint8 block_id;

	for (block_id = 0; block_id <= record->max_block_id; block_id++)
	{
		BufferTag page_tag;
		POLAR_GET_LOG_TAG(record, page_tag, block_id);

		if (BUFFERTAGS_EQUAL(*tag, page_tag))
		{
			/*
			 * Full-page image (FPI) records contain nothing else but a backup
			 * block. The block reference must include a full-page image -
			 * otherwise there would be no point in this record.
			 *
			 * No recovery conflicts are generated by these generic records - if a
			 * resource manager needs to generate conflicts, it has to define a
			 * separate WAL record type and redo routine.
			 *
			 * XLOG_FPI_FOR_HINT records are generated when a page needs to be
			 * WAL- logged because of a hint bit update. They are only generated
			 * when checksums are enabled. There is no difference in handling
			 * XLOG_FPI and XLOG_FPI_FOR_HINT records, they use a different info
			 * code just to distinguish them for statistics purposes.
			 */
			action = POLAR_READ_BUFFER_FOR_REDO(record, block_id, buffer);
			break;
		}
	}

	return action;
}

/*
 * POLAR: fullpage snapshot image wal redo
 */
static XLogRedoAction
xlog_idx_fpsi_redo(polar_logindex_redo_ctl_t instance, XLogReaderState *record, BufferTag *tag, Buffer *buffer)
{
	XLogRedoAction action = BLK_NOTFOUND;
	BufferTag tag0;
	Page    page;
	uint64  fullpage_no = 0;

	POLAR_GET_LOG_TAG(record, tag0, 0);

	if (BUFFERTAGS_EQUAL(*tag, tag0))
	{
		page = BufferGetPage(*buffer);
		/* get fullpage_no from record */
		memcpy(&fullpage_no, XLogRecGetData(record), sizeof(uint64));
		/* read fullpage from file */
		polar_read_fullpage(instance->fullpage_ctl, page, fullpage_no);
		action = BLK_RESTORED;
	}

	return action;
}

void
polar_xlog_idx_save(polar_logindex_redo_ctl_t instance, XLogReaderState *record)
{
	uint8       info = XLogRecGetInfo(record) & ~XLR_INFO_MASK;
	uint8		block_id;

	if (info != XLOG_FPI &&
			info != XLOG_FPI_FOR_HINT &&
			info != XLOG_FPSI)
		return;

	switch (info)
	{
		case XLOG_FPI:
		case XLOG_FPI_FOR_HINT:
		case XLOG_FPSI:
			for (block_id = 0; block_id <= record->max_block_id; block_id++)
				polar_logindex_save_block(instance, record, block_id);
			break;

		default:
			break;
	}
}

bool
polar_xlog_idx_parse(polar_logindex_redo_ctl_t instance, XLogReaderState *record)
{
	uint8       info = XLogRecGetInfo(record) & ~XLR_INFO_MASK;
	uint8		block_id;

	if (info == XLOG_FPI || info == XLOG_FPI_FOR_HINT)
	{
		for (block_id = 0; block_id <= record->max_block_id; block_id++)
			polar_logindex_redo_parse(instance, record, block_id);
		return true;
	}
	else if (info == XLOG_FPSI)
	{
		uint64  fullpage_no = 0;
		/* get fullpage_no from record */
		memcpy(&fullpage_no, XLogRecGetData(record), sizeof(uint64));
		/* Update max_fullpage_no */
		polar_update_max_fullpage_no(instance->fullpage_ctl, fullpage_no);
		return true;
	}

	return false;
}

XLogRedoAction
polar_xlog_idx_redo(polar_logindex_redo_ctl_t instance, XLogReaderState *record,  BufferTag *tag, Buffer *buffer)
{
	uint8       info = XLogRecGetInfo(record) & ~XLR_INFO_MASK;

	/*
	 * These operations don't overwrite MVCC data so no conflict processing is
	 * required. The ones in heap2 rmgr do.
	 */

	switch (info)
	{
		case XLOG_FPI:
		case XLOG_FPI_FOR_HINT:
			return xlog_idx_fpi_redo(record, tag, buffer);

		case XLOG_FPSI:
			return xlog_idx_fpsi_redo(instance, record, tag, buffer);

		default:
			elog(PANIC, "polar_xlog_idx_redo: unknown op code %u", info);
			break;
	}

	return BLK_NOTFOUND;
}
