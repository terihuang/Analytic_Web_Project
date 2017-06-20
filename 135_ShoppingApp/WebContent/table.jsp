<%@ page language="java" contentType="text/html; charset=ISO-8859-1"
    pageEncoding="ISO-8859-1"%>
 <%@ page import = "java.sql.*" import = "java.until.*" import="java.util.List"
	import="java.util.ArrayList"  import = "org.json.JSONObject.*"%>
<%@page import="org.json.simple.JSONArray"%>
<%@page import="org.json.simple.JSONObject"%>
<%@page import="org.json.simple.parser.JSONParser"%>
<%@page import="org.json.simple.parser.ParseException"%>	

<% 

		Connection conn = null;
		PreparedStatement pst = null;
		Statement stmt = null;
		Statement dstmt1 = null;
		Statement dstmt2 = null;
		ResultSet myRs = null;
		ResultSet pRs = null;
		ResultSet tRs= null;
		
		

		try{	
			Class.forName("org.postgresql.Driver");
			conn = DriverManager.getConnection("jdbc:postgresql://localhost/shoppingAppDB","postgres", "cse135");
			String cate = request.getParameter("cate");
			String up = "SELECT * from last";
			conn.setAutoCommit(false);
			stmt = conn.createStatement();
			ResultSet s = stmt.executeQuery(up);
			conn.commit();
			conn.setAutoCommit(true);
			int last = 0;
			while(s.next()){
				last = s.getInt("lu");
			}
			// store top 50 products with their table column index into JSON Object
			String top50Query = "SELECT product_name from top_product";
			conn.setAutoCommit(false);
			stmt = conn.createStatement();
			tRs = stmt.executeQuery(top50Query);
			conn.commit();
			conn.setAutoCommit(true);
			
			
			JSONObject topProds = new JSONObject();
			int topProdCnt = 1;
			int offset = 0;
			if(session.getAttribute("offset") != null ){
				offset = (Integer) session.getAttribute("offset");
				
			}
			while(tRs.next()) {
				topProds.put(tRs.getString("product_name"), topProdCnt );
				topProdCnt++;
			}
			
			tRs.close();
			stmt.close();
			
			
			String logQuery = "SELECT * FROM logtable2 OFFSET " + offset;
			String updateProdQuery = "UPDATE product_with_sale SET spend = spend + ? " + " WHERE product_name = ? ";			
			conn.setAutoCommit(false);
			stmt = conn.createStatement();
			myRs = stmt.executeQuery(logQuery);
			conn.commit();
			conn.setAutoCommit(true);	
			
			JSONObject result = new JSONObject();
			JSONObject diffProdHeader = new JSONObject();
			JSONObject diffStHeader = new JSONObject();			
			
			String update_overall= " UPDATE over_all set cell_sum = cell_sum + ? , product_sum = product_sum + ?, state_sum = state_sum + ? where state_name = ? "+" AND product_name = ? ";
			String st_n, pr_n = "";
			
			
			while (myRs.next()) {
				offset++;
				last++;
				result.put(myRs.getString("state_name") + myRs.getString("product_name"), myRs.getInt("sum"));
				diffProdHeader.put( myRs.getString("product_name"), 1);
				diffStHeader.put( myRs.getString("state_name"), 1);	
				if( last == offset){
				// update product_with_sale table with new sales in log table
				pst = conn.prepareStatement(updateProdQuery);
				pst.setInt(1, myRs.getInt("sum"));
				pst.setString(2, myRs.getString("product_name"));
				int ps = pst.executeUpdate();
				
				pst.close();
				
				st_n = myRs.getString("state_name");
				pr_n = myRs.getString("product_name");
				
				
				
				// update over_all table with new sales in log table
				int amount = myRs.getInt("sum");
				pst = conn.prepareStatement(update_overall);
				pst.setInt(1, amount);
				pst.setInt(2, amount);
				pst.setInt(3, amount);
				pst.setString(4, st_n);
				pst.setString(5, pr_n);
				pst.executeUpdate();
				pst.close();
				}
			}
			session.setAttribute("offset", offset);
			myRs.close();
			stmt.close();
			
			String diffPr = "";
			
			// get different product in top 50, store into JSON object
			if ( cate == null || cate.equals("all")  || cate.equals("null")) {
				
				diffPr = "(select product_name from top_product " +
								" except " +
								" select ps.product_name from (select product_name from product_with_sale order by spend desc limit 50) as ps ) " +
								" UNION ALL " +
								" (select ps.product_name from (select product_name from product_with_sale order by spend desc limit 50) as ps " +
								" except " +
								" select product_name from top_product ) ";
			}
			else{
				
				diffPr = "(select product_name from top_product " +
						" except " +
						" select ps.product_name from (select product_name from product_with_sale WHERE category_name = '" + cate + "' order by spend desc limit 50) as ps ) " +
						" UNION ALL " +
						" (select ps.product_name from (select product_name from product_with_sale WHERE category_name = '" + cate + "' order by spend desc limit 50) as ps " +
						" except " +
						" select product_name from top_product ) ";				
			}
			
			conn.setAutoCommit(false);
			stmt = conn.createStatement();
			pRs = stmt.executeQuery(diffPr);
			conn.commit();
			conn.setAutoCommit(true);	
			JSONObject diffProd = new JSONObject();
			
			while(pRs.next()){
				diffProd.put(pRs.getString("product_name"), 1);			
			}
			
			pRs.close();
			stmt.close();
			
			//TODO: update pre-computation table
			
			
			// clean log table
			String delQuery = "DELETE FROM logtable";
			conn.setAutoCommit(false);			
			dstmt1 = conn.createStatement();
			int rs = dstmt1.executeUpdate(delQuery);
			conn.commit();
			conn.setAutoCommit(true);
			
			dstmt1.close();
			
			/*delQuery = "DELETE FROM logtable2";
			conn.setAutoCommit(false);			
			dstmt2 = conn.createStatement();
			int rs2 = dstmt2.executeUpdate(delQuery);
			conn.commit();
			conn.setAutoCommit(true);
			
			dstmt2.close();			
			*/
			conn.close();

			
			//store two JSON objects into JSON array
			JSONArray jArray = new JSONArray();
			jArray.add(topProds);
			jArray.add(result);
			jArray.add(diffProd);
			jArray.add(diffProdHeader);
			jArray.add(diffStHeader);
			
			JSONObject jObject = new JSONObject();
			jObject.put("info", jArray);
			
		    response.setContentType("text/json");
		    response.getWriter().print(jObject);
			
			
		}
		
		catch(SQLException e){
			out.println("Database connection error !");
		}
		finally{
				if (myRs != null) {
	                try {
	                    myRs.close();
	                } catch (SQLException e) { } // Ignore
	                myRs = null;
	            }
				if (conn != null) {
	                try {
	                    conn.close();
	                } catch (SQLException e) { } // Ignore
	                conn = null;
	            }
		}	
		
		
		%>	
